#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist/apps"
BUILD_ROOT="${ROOT}/build/apps"
WORKSPACE_ROOT="${CYPHER_OS_WORKSPACE_ROOT:-$(cd "${ROOT}/.." && pwd)}"
CARDPUTER_FQBN="m5stack:esp32:m5stack_cardputer:FlashSize=8M,PartitionScheme=default_8MB,CDCOnBoot=cdc,USBMode=hwcdc"
RETURN_LIB="${ROOT}/libraries/CypherPuterReturn"

CARDPUTER_GAMES_ROOT="${CYPHER_OS_CARDPUTER_GAMES_DIR:-${WORKSPACE_ROOT}/cardputer-games}"
CARDPUTER_MPC_ROOT="${CYPHER_OS_CARDPUTER_MPC_DIR:-${WORKSPACE_ROOT}/cardputer-mpc}"
CARDPUTER_TAROT_ROOT="${CYPHER_OS_CARDPUTER_TAROT_DIR:-${WORKSPACE_ROOT}/cardputer-tarot}"
CYPHER_CHAT_ROOT="${CYPHER_OS_CYPHER_CHAT_DIR:-${WORKSPACE_ROOT}/cypher-chat/cypher-chat-firmware}"
CYPHER_DRIVE_ROOT="${CYPHER_OS_CYPHER_DRIVE_DIR:-${WORKSPACE_ROOT}/cypher-drive}"
CYPHER_DESK_ROOT="${CYPHER_OS_CYPHER_DESK_DIR:-${WORKSPACE_ROOT}/cypher-desk}"
FLOCK_YOU_ROOT="${CYPHER_OS_FLOCK_YOU_DIR:-${WORKSPACE_ROOT}/flock-you}"
WIRETAP_ROOT="${CYPHER_OS_WIRETAP_DIR:-${WORKSPACE_ROOT}/WireTap-32}"
GAME_OS_ROOT="${CYPHER_OS_GAME_OS_DIR:-${WORKSPACE_ROOT}/cardputer-game-os}"
GAME_OS_APPS="${GAME_OS_ROOT}/dist/apps"
GAME_OS_MANIFEST="${GAME_OS_APPS}/games.json"

rm -rf "${DIST}"
mkdir -p "${DIST}" "${BUILD_ROOT}"

CARDPUTER_GAMES_STATUS="build_missing"
CARDPUTER_MPC_STATUS="build_missing"
CARDPUTER_TAROT_STATUS="build_missing"
CYPHER_CHAT_STATUS="build_missing"
CYPHER_DRIVE_STATUS="build_missing"
CYPHER_DESK_STATUS="build_missing"
FLOCK_YOU_STATUS="build_missing"
WIRETAP_STATUS="build_missing"
GAME_OS_STATUS="build_missing"

copy_app_bin() {
  local build_dir="$1"
  local dest="$2"
  local found=""

  found="$(find "${build_dir}" -maxdepth 1 -type f -name "*.ino.bin" | head -n 1 || true)"
  if [[ -z "${found}" ]]; then
    found="$(find "${build_dir}" -maxdepth 1 -type f -name "*.bin" \
      ! -name "*.merged.bin" ! -name "*.bootloader.bin" ! -name "*.partitions.bin" | head -n 1 || true)"
  fi

  if [[ -z "${found}" ]]; then
    echo "[apps] no app .bin found in ${build_dir}"
    return 1
  fi

  cp -f "${found}" "${DIST}/${dest}"
  echo "[apps] packaged ${dest}"
}

require_dir() {
  local name="$1"
  local path="$2"

  if [[ ! -d "${path}" ]]; then
    echo "[apps] missing ${name}: ${path}"
    return 1
  fi
}

build_cardputer_games() {
  local src="${CARDPUTER_GAMES_ROOT}"
  local out="${BUILD_ROOT}/cardputer-games"
  require_dir "cardputer-games source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building cardputer-games"
  arduino-cli compile --fqbn "${CARDPUTER_FQBN}" --library "${RETURN_LIB}" --output-dir "${out}" "${src}" || return 1
  copy_app_bin "${out}" "cardputer-games.bin" || return 1
  CARDPUTER_GAMES_STATUS="ready"
}

build_cardputer_mpc() {
  local src="${CARDPUTER_MPC_ROOT}"
  local out="${BUILD_ROOT}/cardputer-mpc"
  require_dir "cardputer-mpc source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building cardputer-mpc"
  arduino-cli compile --profile cardputer --output-dir "${out}" "${src}" || return 1
  copy_app_bin "${out}" "cardputer-mpc.bin" || return 1
  CARDPUTER_MPC_STATUS="ready"
}

build_cardputer_tarot() {
  local src="${CARDPUTER_TAROT_ROOT}/CardputerTarot"
  local out="${BUILD_ROOT}/cardputer-tarot"
  require_dir "cardputer-tarot source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building cardputer-tarot"
  arduino-cli compile --fqbn "${CARDPUTER_FQBN}" --library "${RETURN_LIB}" --output-dir "${out}" "${src}" || return 1
  copy_app_bin "${out}" "cardputer-tarot.bin" || return 1
  CARDPUTER_TAROT_STATUS="ready"
}

build_cypher_chat() {
  local src="${CYPHER_CHAT_ROOT}"
  local out="${BUILD_ROOT}/cypher-chat"
  require_dir "cypher-chat source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building cypher-chat"
  arduino-cli compile \
    --fqbn "${CARDPUTER_FQBN}" \
    --library "${RETURN_LIB}" \
    --output-dir "${out}" \
    --build-property "build.extra_flags=-DESP32 -DBOARD_PROFILE=BOARD_PROFILE_CARDPUTER_ADV" \
    "${src}" || return 1
  copy_app_bin "${out}" "cypher-chat.bin" || return 1
  CYPHER_CHAT_STATUS="ready"
}

build_cypher_drive() {
  local src="${CYPHER_DRIVE_ROOT}"
  local out="${BUILD_ROOT}/cypher-drive"
  local fqbn="esp32:esp32:m5stack_cardputer:FlashSize=8M,PSRAM=disabled,USBMode=default,CDCOnBoot=cdc,PartitionScheme=default_8MB"
  require_dir "cypher-drive source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building cypher-drive"
  arduino-cli compile \
    --fqbn "${fqbn}" \
    --library "${RETURN_LIB}" \
    --output-dir "${out}" \
    --build-property "build.extra_flags=-DESP32 -DBOARD_PROFILE=BOARD_PROFILE_M5STACK_CARDPUTER_ADV" \
    --build-property "recipe.hooks.prebuild.1.pattern=/usr/bin/env bash -c 'cp -f \"{build.source.path}\"/partitions_cardputer_8mb.csv \"{build.path}\"/partitions.csv'" \
    "${src}" || return 1
  copy_app_bin "${out}" "cypher-drive.bin" || return 1
  CYPHER_DRIVE_STATUS="ready"
}

build_cypher_desk() {
  local src="${CYPHER_DESK_ROOT}"
  local out="${BUILD_ROOT}/cypher-desk"
  require_dir "cypher-desk source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building cypher-desk"
  arduino-cli compile --fqbn "${CARDPUTER_FQBN}" --library "${RETURN_LIB}" --output-dir "${out}" "${src}" || return 1
  copy_app_bin "${out}" "cypher-desk.bin" || return 1
  CYPHER_DESK_STATUS="ready"
}

build_flock_you() {
  local src="${FLOCK_YOU_ROOT}"
  local out="${BUILD_ROOT}/flock-you"
  require_dir "flock-you source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building flock-you"
  arduino-cli compile \
    --fqbn "${CARDPUTER_FQBN}" \
    --library "${RETURN_LIB}" \
    --output-dir "${out}" \
    --build-property "build.extra_flags=-DESP32 -DBOARD_PROFILE=ESP32_CARDPUTER_ADV" \
    "${src}" || return 1
  copy_app_bin "${out}" "flock-you.bin" || return 1
  FLOCK_YOU_STATUS="ready"
}

build_wiretap() {
  local src="${WIRETAP_ROOT}"
  local out="${BUILD_ROOT}/wiretap-32-cardputer"
  require_dir "wiretap-32 source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building wiretap-32-cardputer"
  arduino-cli compile \
    --fqbn "${CARDPUTER_FQBN}" \
    --library "${RETURN_LIB}" \
    --output-dir "${out}" \
    --build-property "build.extra_flags=-DESP32 -DWIRETAP_CARDPUTER_ADV=1" \
    "${src}" || return 1
  copy_app_bin "${out}" "wiretap-32-cardputer.bin" || return 1
  WIRETAP_STATUS="ready"
}

build_game_os_games() {
  require_dir "cardputer-game-os source" "${GAME_OS_ROOT}" || return 1

  if [[ ! -x "${GAME_OS_ROOT}/tools/build-games.sh" ]]; then
    echo "[apps] missing ${GAME_OS_ROOT}/tools/build-games.sh"
    return 1
  fi

  echo "[apps] building cardputer-game-os games"
  "${GAME_OS_ROOT}/tools/build-games.sh" || return 1

  if [[ ! -f "${GAME_OS_MANIFEST}" ]]; then
    echo "[apps] missing ${GAME_OS_MANIFEST}"
    return 1
  fi

  while IFS= read -r bin; do
    cp -f "${bin}" "${DIST}/"
    echo "[apps] imported $(basename "${bin}")"
  done < <(find "${GAME_OS_APPS}" -maxdepth 1 -type f -name "*.bin" \
    ! -name "*.merged.bin" ! -name "*.bootloader.bin" ! -name "*.partitions.bin" | sort)

  GAME_OS_STATUS="ready"
}

mark_failed() {
  local name="$1"
  echo "[apps] ${name} failed; leaving manifest status as build_failed"
  case "${name}" in
    cardputer-games) CARDPUTER_GAMES_STATUS="build_failed" ;;
    cardputer-mpc) CARDPUTER_MPC_STATUS="build_failed" ;;
    cardputer-tarot) CARDPUTER_TAROT_STATUS="build_failed" ;;
    cypher-chat) CYPHER_CHAT_STATUS="build_failed" ;;
    cypher-drive) CYPHER_DRIVE_STATUS="build_failed" ;;
    cypher-desk) CYPHER_DESK_STATUS="build_failed" ;;
    flock-you) FLOCK_YOU_STATUS="build_failed" ;;
    wiretap-32-cardputer) WIRETAP_STATUS="build_failed" ;;
    cardputer-game-os-games) GAME_OS_STATUS="build_failed" ;;
  esac
}

build_cardputer_games || mark_failed "cardputer-games"
build_cardputer_mpc || mark_failed "cardputer-mpc"
build_cardputer_tarot || mark_failed "cardputer-tarot"
build_cypher_chat || mark_failed "cypher-chat"
build_cypher_drive || mark_failed "cypher-drive"
build_cypher_desk || mark_failed "cypher-desk"
build_flock_you || mark_failed "flock-you"
build_wiretap || mark_failed "wiretap-32-cardputer"
build_game_os_games || mark_failed "cardputer-game-os-games"

CARDPUTER_GAMES_STATUS="${CARDPUTER_GAMES_STATUS}" \
CARDPUTER_MPC_STATUS="${CARDPUTER_MPC_STATUS}" \
CARDPUTER_TAROT_STATUS="${CARDPUTER_TAROT_STATUS}" \
CYPHER_CHAT_STATUS="${CYPHER_CHAT_STATUS}" \
CYPHER_DRIVE_STATUS="${CYPHER_DRIVE_STATUS}" \
CYPHER_DESK_STATUS="${CYPHER_DESK_STATUS}" \
FLOCK_YOU_STATUS="${FLOCK_YOU_STATUS}" \
WIRETAP_STATUS="${WIRETAP_STATUS}" \
GAME_OS_STATUS="${GAME_OS_STATUS}" \
CARDPUTER_GAMES_ROOT="${CARDPUTER_GAMES_ROOT}" \
CARDPUTER_MPC_ROOT="${CARDPUTER_MPC_ROOT}" \
CARDPUTER_TAROT_ROOT="${CARDPUTER_TAROT_ROOT}" \
CYPHER_CHAT_ROOT="${CYPHER_CHAT_ROOT}" \
CYPHER_DRIVE_ROOT="${CYPHER_DRIVE_ROOT}" \
CYPHER_DESK_ROOT="${CYPHER_DESK_ROOT}" \
FLOCK_YOU_ROOT="${FLOCK_YOU_ROOT}" \
WIRETAP_ROOT="${WIRETAP_ROOT}" \
GAME_OS_ROOT="${GAME_OS_ROOT}" \
python3 - "${DIST}/apps.json" "${GAME_OS_MANIFEST}" <<'PY'
import json
import os
import sys

out_path = sys.argv[1]
game_manifest = sys.argv[2]

def status(name):
    return os.environ[name]

def binary(app_status, filename):
    return filename if app_status == "ready" else ""

def path(name):
    return os.environ[name]

apps = [
    {
        "name": "Cypher Drive",
        "slug": "cypher-drive",
        "binary": binary(status("CYPHER_DRIVE_STATUS"), "cypher-drive.bin"),
        "source_path": path("CYPHER_DRIVE_ROOT"),
        "version": "local",
        "status": status("CYPHER_DRIVE_STATUS"),
        "notes": "Cardputer ADV HID payload launcher build.",
    },
    {
        "name": "Cypher Chat",
        "slug": "cypher-chat",
        "binary": binary(status("CYPHER_CHAT_STATUS"), "cypher-chat.bin"),
        "source_path": path("CYPHER_CHAT_ROOT"),
        "version": "local",
        "status": status("CYPHER_CHAT_STATUS"),
        "notes": "Cardputer ADV secure-only mesh chat build. Mesh protocol 0x02 uses AES-256-GCM and does not interoperate with plaintext or HMAC-only firmware.",
    },
    {
        "name": "Cardputer Games",
        "slug": "cardputer-games",
        "binary": binary(status("CARDPUTER_GAMES_STATUS"), "cardputer-games.bin"),
        "source_path": path("CARDPUTER_GAMES_ROOT"),
        "version": "local",
        "status": status("CARDPUTER_GAMES_STATUS"),
        "notes": "Standalone Cardputer arcade catalog.",
    },
    {
        "name": "Cardputer MPC",
        "slug": "cardputer-mpc",
        "binary": binary(status("CARDPUTER_MPC_STATUS"), "cardputer-mpc.bin"),
        "source_path": path("CARDPUTER_MPC_ROOT"),
        "version": "local",
        "status": status("CARDPUTER_MPC_STATUS"),
        "notes": "MPC-style groovebox with SD-loaded samples and sequencing. Press Shift+Q to return to Cypher OS.",
    },
    {
        "name": "Cardputer Tarot",
        "slug": "cardputer-tarot",
        "binary": binary(status("CARDPUTER_TAROT_STATUS"), "cardputer-tarot.bin"),
        "source_path": path("CARDPUTER_TAROT_ROOT"),
        "version": "local",
        "status": status("CARDPUTER_TAROT_STATUS"),
        "notes": "Offline tarot pull, journal, history, and study deck app. Back/backtick from the main menu returns to Cypher OS.",
    },
    {
        "name": "Cypher Desk",
        "slug": "cypher-desk",
        "binary": binary(status("CYPHER_DESK_STATUS"), "cypher-desk.bin"),
        "source_path": path("CYPHER_DESK_ROOT"),
        "version": "local",
        "status": status("CYPHER_DESK_STATUS"),
        "notes": "Offline Cardputer ADV utility suite with notes, calculator, checklist, converters, and scratchpad.",
    },
    {
        "name": "Flock You",
        "slug": "flock-you",
        "binary": binary(status("FLOCK_YOU_STATUS"), "flock-you.bin"),
        "source_path": path("FLOCK_YOU_ROOT"),
        "version": "local-cardputer",
        "status": status("FLOCK_YOU_STATUS"),
        "notes": "Cardputer ADV WiFi/BLE detector build with return-to-launcher support.",
    },
    {
        "name": "WireTap-32 Cardputer",
        "slug": "wiretap-32-cardputer",
        "binary": binary(status("WIRETAP_STATUS"), "wiretap-32-cardputer.bin"),
        "source_path": path("WIRETAP_ROOT"),
        "version": "local-cardputer",
        "status": status("WIRETAP_STATUS"),
        "notes": "Cardputer ADV EXT bench build with return-to-launcher support.",
    },
]

if status("GAME_OS_STATUS") == "ready" and os.path.exists(game_manifest):
    with open(game_manifest, "r", encoding="utf-8") as handle:
        data = json.load(handle)
    games = data if isinstance(data, list) else data.get("games", [])
    for game in games:
        apps.append(
            {
                "name": game.get("name", "Game OS App"),
                "slug": game.get("slug", ""),
                "binary": game.get("binary", ""),
                "source_path": game.get("source_path", path("GAME_OS_ROOT")),
                "version": game.get("version", "local"),
                "status": game.get("status", "ready"),
                "notes": "Cardputer Game OS import. " + game.get("notes", ""),
            }
        )

with open(out_path, "w", encoding="utf-8") as handle:
    json.dump({"apps": apps}, handle, indent=2)
    handle.write("\n")
PY

echo "[apps] manifest: ${DIST}/apps.json"

if [[ "${CARDPUTER_GAMES_STATUS}" != "ready" || "${CARDPUTER_MPC_STATUS}" != "ready" || "${CARDPUTER_TAROT_STATUS}" != "ready" || "${CYPHER_CHAT_STATUS}" != "ready" || "${CYPHER_DRIVE_STATUS}" != "ready" || "${CYPHER_DESK_STATUS}" != "ready" || "${FLOCK_YOU_STATUS}" != "ready" || "${WIRETAP_STATUS}" != "ready" || "${GAME_OS_STATUS}" != "ready" ]]; then
  echo "[apps] one or more ready apps failed to build"
  exit 1
fi
