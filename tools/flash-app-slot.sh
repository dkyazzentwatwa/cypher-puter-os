#!/usr/bin/env bash
# Dev-loop helper: write an app .bin into the Cypher OS app slot (ota_1) over USB and boot it,
# without rewriting the launcher in ota_0. Works with any partition table on the device: the
# slot is located by reading the table, and the boot selection is written to otadata the same
# way the launcher's esp_ota_set_boot_partition() does.
set -euo pipefail

BIN=""
PORT=""
MODE="flash"

usage() {
  cat <<'USAGE'
Usage: ./tools/flash-app-slot.sh <app.bin> [/dev/cu.usbmodemXXXX]
       ./tools/flash-app-slot.sh --restore [/dev/cu.usbmodemXXXX]

<app.bin>  A sketch app .bin (not a merged image). It is written into the ota_1
           slot and selected as the boot partition; the device then reboots into it.
--restore  Select ota_0 (the launcher) again without flashing anything.

The launcher lists a slot filled this way as "Unknown app" because no catalog
install recorded a name. Returning to Cypher OS from the app works as usual.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --restore) MODE="restore"; shift ;;
    *)
      if [[ -z "${BIN}" && "${MODE}" == "flash" ]]; then BIN="$1"
      elif [[ -z "${PORT}" ]]; then PORT="$1"
      else echo "[slot] unexpected argument: $1" >&2; usage >&2; exit 2
      fi
      shift ;;
  esac
done

detect_port() {
  ls /dev/cu.usbmodem* 2>/dev/null | head -n 1 || true
}

find_esptool() {
  # Newest bundled esptool first: watchdog_reset needs esptool >= 4.7.
  local candidate
  candidate="$(ls -d "${HOME}"/Library/Arduino15/packages/*/tools/esptool_py/*/esptool 2>/dev/null \
    | awk -F/ '{print $(NF-1) "\t" $0}' | sort -t$'\t' -k1,1V | tail -n 1 | cut -f2)"
  if [[ -n "${candidate}" && -x "${candidate}" ]]; then
    echo "${candidate}"
    return 0
  fi
  if command -v esptool.py >/dev/null 2>&1; then
    echo "esptool.py"
    return 0
  fi
  return 1
}

# Put the chip into the ROM bootloader. A TinyUSB CDC port (launcher builds) needs the
# 1200-baud touch; a USB-JTAG port ignores it and esptool's default reset handles it.
enter_bootloader() {
  stty -f "${PORT}" 1200 2>/dev/null || true
  sleep 2
  local waited=0
  while [[ ! -e "${PORT}" && ${waited} -lt 20 ]]; do
    sleep 0.5
    waited=$((waited + 1))
    PORT="$(detect_port)"
  done
}

if [[ "${MODE}" == "flash" ]]; then
  if [[ -z "${BIN}" ]]; then usage >&2; exit 2; fi
  if [[ ! -f "${BIN}" ]]; then echo "[slot] missing binary: ${BIN}" >&2; exit 1; fi
  magic="$(head -c 1 "${BIN}" | xxd -p)"
  if [[ "${magic}" != "e9" ]]; then
    echo "[slot] ${BIN} does not start with the ESP app image magic 0xE9; use a sketch .bin, not a merged image" >&2
    exit 1
  fi
fi

ESPTOOL="$(find_esptool)" || { echo "[slot] esptool not found; install the esp32 core with arduino-cli first" >&2; exit 1; }
[[ -n "${PORT}" ]] || PORT="$(detect_port)"
[[ -n "${PORT}" ]] || { echo "[slot] no /dev/cu.usbmodem* port found; connect the Cardputer ADV" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

enter_bootloader
echo "[slot] reading partition table via ${PORT}"
"${ESPTOOL}" --chip esp32s3 --port "${PORT}" --before default_reset --after no_reset \
  read_flash 0x8000 0xC00 "${WORK}/parttable.bin" >/dev/null

# Prints: <ota1_offset> <ota1_size> <otadata_offset>
read -r OTA1_OFF OTA1_SIZE OTADATA_OFF < <(python3 - "${WORK}/parttable.bin" <<'PY'
import struct, sys
data = open(sys.argv[1], "rb").read()
ota1 = otadata = None
for i in range(0, len(data), 32):
    magic, ptype, subtype, offset, size = struct.unpack_from("<HBBII", data, i)
    if magic != 0x50AA:
        break
    if ptype == 0x00 and subtype == 0x11:
        ota1 = (offset, size)
    if ptype == 0x01 and subtype == 0x00:
        otadata = offset
if ota1 is None or otadata is None:
    sys.exit("partition table has no ota_1 app slot or no otadata")
print(ota1[0], ota1[1], otadata)
PY
)
printf '[slot] ota_1 slot at 0x%X (%d bytes), otadata at 0x%X\n' "${OTA1_OFF}" "${OTA1_SIZE}" "${OTADATA_OFF}"

if [[ "${MODE}" == "flash" ]]; then
  size="$(stat -f %z "${BIN}")"
  if (( size > OTA1_SIZE )); then
    echo "[slot] ${BIN} is ${size} bytes; the ota_1 slot holds ${OTA1_SIZE}" >&2
    exit 1
  fi
  echo "[slot] writing ${BIN} (${size} bytes)"
  "${ESPTOOL}" --chip esp32s3 --port "${PORT}" --baud 921600 --before no_reset --after no_reset \
    write_flash "$(printf '0x%X' "${OTA1_OFF}")" "${BIN}" | grep -E 'Wrote|Hash|error' || true
  TARGET=1
else
  TARGET=0
fi

# Select the boot slot: the entry with the highest valid ota_seq wins, and (seq - 1) % 2
# picks the slot, so write the next qualifying seq into the sector that is not current.
"${ESPTOOL}" --chip esp32s3 --port "${PORT}" --before no_reset --after no_reset \
  read_flash "$(printf '0x%X' "${OTADATA_OFF}")" 0x2000 "${WORK}/otadata.bin" >/dev/null
read -r SECTOR SEQ < <(python3 - "${WORK}/otadata.bin" "${TARGET}" "${WORK}/otasector.bin" <<'PY'
import struct, sys, zlib
data = open(sys.argv[1], "rb").read()
target = int(sys.argv[2])
def crc(seq):
    return zlib.crc32(struct.pack("<I", seq), 0xFFFFFFFF) & 0xFFFFFFFF
best = None  # (seq, sector)
for sector in (0, 1):
    seq, = struct.unpack_from("<I", data, sector * 0x1000)
    stored, = struct.unpack_from("<I", data, sector * 0x1000 + 28)
    if seq != 0xFFFFFFFF and stored == crc(seq):
        if best is None or seq > best[0]:
            best = (seq, sector)
current_seq = best[0] if best else 0
new_seq = current_seq + 1
while (new_seq - 1) % 2 != target:
    new_seq += 1
sector = 1 - best[1] if best else 0
entry = struct.pack("<I", new_seq) + b"\xFF" * 20 + struct.pack("<II", 2, crc(new_seq))
open(sys.argv[3], "wb").write(entry + b"\xFF" * (0x1000 - len(entry)))
print(sector, new_seq)
PY
)
echo "[slot] selecting ota_${TARGET} (otadata sector ${SECTOR}, seq ${SEQ})"
"${ESPTOOL}" --chip esp32s3 --port "${PORT}" --before no_reset --after watchdog_reset \
  write_flash "$(printf '0x%X' $((OTADATA_OFF + SECTOR * 0x1000)))" "${WORK}/otasector.bin" | grep -E 'Wrote|Hash|error|watchdog' || true
echo "[slot] done; the Cardputer is rebooting into ota_${TARGET}"
