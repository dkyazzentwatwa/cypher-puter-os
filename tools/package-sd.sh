#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_ROOT="${CYPHER_OS_WORKSPACE_ROOT:-$(cd "${ROOT}/.." && pwd)}"
APP_DIST="${ROOT}/dist/apps"
SD_ROOT="${ROOT}/dist/sd-card"
SD_APPS="${SD_ROOT}/cypher-puter/apps"
SD_GAME_OS_SAVES="${SD_ROOT}/cardputer-game-os/saves"
CARDPUTER_MPC_ROOT="${CYPHER_OS_CARDPUTER_MPC_DIR:-${WORKSPACE_ROOT}/cardputer-mpc}"
ESP32_BT_HID_ROOT="${CYPHER_OS_ESP32_BT_HID_DIR:-${WORKSPACE_ROOT}/ESP32_BT_HID}"
DRONE_MESH_MAPPER_ROOT="${CYPHER_OS_DRONE_MESH_MAPPER_DIR:-${WORKSPACE_ROOT}/drone-mesh-mapper}"
MPC_SD_SRC="${CARDPUTER_MPC_ROOT}/sdcard/cardputer-mpc"
ESP32_BT_HID_SD_SRC="${ESP32_BT_HID_ROOT}/dist/sd-card/cypher-drive"
DRONE_MESH_MAPPER_SD_SRC="${DRONE_MESH_MAPPER_ROOT}/sd/drone"
MANIFEST="${APP_DIST}/apps.json"

if [[ ! -f "${MANIFEST}" ]]; then
  echo "[sd] missing ${MANIFEST}"
  echo "[sd] run ./tools/build-apps.sh before packaging the SD card"
  exit 1
fi

rm -rf "${SD_ROOT}"
mkdir -p "${SD_APPS}" "${SD_GAME_OS_SAVES}"

cp -f "${MANIFEST}" "${SD_APPS}/apps.json"

python3 - "${MANIFEST}" <<'PY' | while IFS= read -r binary; do
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = json.load(handle)
for app in data.get("apps", []):
    binary = app.get("binary", "")
    if app.get("status") == "ready" and binary:
        print(binary)
PY
  if [[ -f "${APP_DIST}/${binary}" ]]; then
    cp -f "${APP_DIST}/${binary}" "${SD_APPS}/"
  else
    echo "[sd] warning: manifest references missing binary ${binary}"
  fi
done

if [[ -d "${MPC_SD_SRC}" ]]; then
  cp -R "${MPC_SD_SRC}" "${SD_ROOT}/"
else
  echo "[sd] warning: ${MPC_SD_SRC} missing; Cardputer MPC will use its fallback kit"
fi

if [[ -x "${ESP32_BT_HID_ROOT}/tools/package-sd.sh" ]]; then
  echo "[sd] packaging ESP32 BT HID payloads"
  (cd "${ESP32_BT_HID_ROOT}" && ./tools/package-sd.sh)
else
  echo "[sd] warning: ${ESP32_BT_HID_ROOT}/tools/package-sd.sh missing; ESP32 BT HID will seed only its fallback payload"
fi

if [[ -d "${ESP32_BT_HID_SD_SRC}" ]]; then
  mkdir -p "${SD_ROOT}/cypher-drive"
  cp -R "${ESP32_BT_HID_SD_SRC}/." "${SD_ROOT}/cypher-drive/"
else
  echo "[sd] warning: ${ESP32_BT_HID_SD_SRC} missing; ESP32 BT HID payload bundle was not copied"
fi

if [[ -d "${DRONE_MESH_MAPPER_SD_SRC}" ]]; then
  mkdir -p "${SD_ROOT}/drone"
  cp -R "${DRONE_MESH_MAPPER_SD_SRC}/." "${SD_ROOT}/drone/"
else
  echo "[sd] warning: ${DRONE_MESH_MAPPER_SD_SRC} missing; Drone Mesh Mapper will create /drone/logs at runtime"
fi

python3 "${ROOT}/tools/validate-catalog.py" "${ROOT}/config/apps.json" --manifest "${SD_APPS}/apps.json" --dist "${SD_APPS}"

echo "[sd] prepared ${SD_ROOT}"
echo "[sd] copy the contents of ${SD_ROOT} to the root of a FAT32 SD card"
