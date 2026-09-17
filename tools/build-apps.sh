#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist/apps"
BUILD_ROOT="${ROOT}/build/apps"
CATALOG="${ROOT}/config/apps.json"
REPORT="${ROOT}/dist/BUILD_REPORT.md"
WORKSPACE_ROOT="${CYPHER_OS_WORKSPACE_ROOT:-$(cd "${ROOT}/.." && pwd)}"
CARDPUTER_FQBN="m5stack:esp32:m5stack_cardputer:FlashSize=8M,PartitionScheme=default_8MB,CDCOnBoot=cdc,USBMode=hwcdc"
RETURN_LIB="${ROOT}/libraries/CypherPuterReturn"
REQUESTED_APP=""

usage() {
  cat <<'EOF'
Usage: ./tools/build-apps.sh [--app <slug>]

Build Cypher OS app binaries into dist/apps and write:
  dist/apps/apps.json
  dist/BUILD_REPORT.md

Without --app, all public catalog apps are built. With --app, only that primary
app slug is built. Use --app cardputer-game-os-games to rebuild imported Game OS
titles.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      if [[ $# -lt 2 ]]; then
        echo "[apps] --app requires a slug" >&2
        exit 2
      fi
      REQUESTED_APP="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "[apps] unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "${REQUESTED_APP}" in
  ""|cardputer-games|cardputer-mpc|cardputer-tarot|cypher-pn532|cypher-chat|cypher-drive|esp32-bt-hid|esp32-pokedex|cypher-desk|flock-you|wiretap-32-cardputer|drone-mesh-mapper|cypher-airtag|bitcoin-card-wallet|cardputer-game-station-emulators|esp32-bit-pirate|esp32-usb-stick|news-reader|open-wifi-scanner|password-manager|ultimate-remote|cardputer-game-os-games) ;;
  *)
    echo "[apps] unknown app slug: ${REQUESTED_APP}" >&2
    exit 2
    ;;
esac

CARDPUTER_GAMES_ROOT="${CYPHER_OS_CARDPUTER_GAMES_DIR:-${WORKSPACE_ROOT}/cardputer-games}"
CARDPUTER_MPC_ROOT="${CYPHER_OS_CARDPUTER_MPC_DIR:-${WORKSPACE_ROOT}/cardputer-mpc}"
CARDPUTER_TAROT_ROOT="${CYPHER_OS_CARDPUTER_TAROT_DIR:-${WORKSPACE_ROOT}/cardputer-tarot}"
CYPHER_PN532_ROOT="${CYPHER_OS_CYPHER_PN532_DIR:-${WORKSPACE_ROOT}/cypher-pn532}"
CYPHER_CHAT_ROOT="${CYPHER_OS_CYPHER_CHAT_DIR:-${WORKSPACE_ROOT}/cypher-chat/cypher-chat-firmware}"
CYPHER_DRIVE_ROOT="${CYPHER_OS_CYPHER_DRIVE_DIR:-${WORKSPACE_ROOT}/cypher-drive}"
ESP32_BT_HID_ROOT="${CYPHER_OS_ESP32_BT_HID_DIR:-${WORKSPACE_ROOT}/ESP32_BT_HID}"
ESP32_POKEDEX_ROOT="${CYPHER_OS_ESP32_POKEDEX_DIR:-${WORKSPACE_ROOT}/esp32-pokedex}"
CYPHER_DESK_ROOT="${CYPHER_OS_CYPHER_DESK_DIR:-${WORKSPACE_ROOT}/cypher-desk}"
FLOCK_YOU_ROOT="${CYPHER_OS_FLOCK_YOU_DIR:-${WORKSPACE_ROOT}/flock-you}"
WIRETAP_ROOT="${CYPHER_OS_WIRETAP_DIR:-${WORKSPACE_ROOT}/WireTap-32}"
DRONE_MESH_MAPPER_ROOT="${CYPHER_OS_DRONE_MESH_MAPPER_DIR:-${WORKSPACE_ROOT}/drone-mesh-mapper}"
CYPHER_AIRTAG_ROOT="${CYPHER_OS_CYPHER_AIRTAG_DIR:-${WORKSPACE_ROOT}/cypher-airtag}"
CARDPUTER_APP_BUNDLE_ROOT="${CYPHER_OS_CARDPUTER_APP_BUNDLE_DIR:-${WORKSPACE_ROOT}/new-cardputer-apps}"
GAME_OS_ROOT="${CYPHER_OS_GAME_OS_DIR:-${WORKSPACE_ROOT}/cardputer-game-os}"
GAME_OS_APPS="${GAME_OS_ROOT}/dist/apps"
GAME_OS_MANIFEST="${GAME_OS_APPS}/games.json"

rm -rf "${DIST}"
mkdir -p "${DIST}" "${BUILD_ROOT}"

if [[ -f "${CATALOG}" ]]; then
  python3 "${ROOT}/tools/validate-catalog.py" "${CATALOG}"
fi

CARDPUTER_GAMES_STATUS="build_missing"
CARDPUTER_MPC_STATUS="build_missing"
CARDPUTER_TAROT_STATUS="build_missing"
CYPHER_PN532_STATUS="build_missing"
CYPHER_CHAT_STATUS="build_missing"
CYPHER_DRIVE_STATUS="build_missing"
ESP32_BT_HID_STATUS="build_missing"
ESP32_POKEDEX_STATUS="build_missing"
CYPHER_DESK_STATUS="build_missing"
FLOCK_YOU_STATUS="build_missing"
WIRETAP_STATUS="build_missing"
DRONE_MESH_MAPPER_STATUS="build_missing"
CYPHER_AIRTAG_STATUS="build_missing"
BITCOIN_CARD_WALLET_STATUS="build_missing"
CARDPUTER_GAME_STATION_EMULATORS_STATUS="build_missing"
ESP32_BIT_PIRATE_STATUS="build_missing"
ESP32_USB_STICK_STATUS="build_missing"
NEWS_READER_STATUS="build_missing"
OPEN_WIFI_SCANNER_STATUS="build_missing"
PASSWORD_MANAGER_STATUS="build_missing"
ULTIMATE_REMOTE_STATUS="build_missing"
GAME_OS_STATUS="build_missing"

set_status() {
  local slug="$1"
  local status="$2"
  case "${slug}" in
    cardputer-games) CARDPUTER_GAMES_STATUS="${status}" ;;
    cardputer-mpc) CARDPUTER_MPC_STATUS="${status}" ;;
    cardputer-tarot) CARDPUTER_TAROT_STATUS="${status}" ;;
    cypher-pn532) CYPHER_PN532_STATUS="${status}" ;;
    cypher-chat) CYPHER_CHAT_STATUS="${status}" ;;
    cypher-drive) CYPHER_DRIVE_STATUS="${status}" ;;
    esp32-bt-hid) ESP32_BT_HID_STATUS="${status}" ;;
    esp32-pokedex) ESP32_POKEDEX_STATUS="${status}" ;;
    cypher-desk) CYPHER_DESK_STATUS="${status}" ;;
    flock-you) FLOCK_YOU_STATUS="${status}" ;;
    wiretap-32-cardputer) WIRETAP_STATUS="${status}" ;;
    drone-mesh-mapper) DRONE_MESH_MAPPER_STATUS="${status}" ;;
    cypher-airtag) CYPHER_AIRTAG_STATUS="${status}" ;;
    bitcoin-card-wallet) BITCOIN_CARD_WALLET_STATUS="${status}" ;;
    cardputer-game-station-emulators) CARDPUTER_GAME_STATION_EMULATORS_STATUS="${status}" ;;
    esp32-bit-pirate) ESP32_BIT_PIRATE_STATUS="${status}" ;;
    esp32-usb-stick) ESP32_USB_STICK_STATUS="${status}" ;;
    news-reader) NEWS_READER_STATUS="${status}" ;;
    open-wifi-scanner) OPEN_WIFI_SCANNER_STATUS="${status}" ;;
    password-manager) PASSWORD_MANAGER_STATUS="${status}" ;;
    ultimate-remote) ULTIMATE_REMOTE_STATUS="${status}" ;;
    cardputer-game-os-games) GAME_OS_STATUS="${status}" ;;
  esac
}

get_status() {
  local slug="$1"
  case "${slug}" in
    cardputer-games) echo "${CARDPUTER_GAMES_STATUS}" ;;
    cardputer-mpc) echo "${CARDPUTER_MPC_STATUS}" ;;
    cardputer-tarot) echo "${CARDPUTER_TAROT_STATUS}" ;;
    cypher-pn532) echo "${CYPHER_PN532_STATUS}" ;;
    cypher-chat) echo "${CYPHER_CHAT_STATUS}" ;;
    cypher-drive) echo "${CYPHER_DRIVE_STATUS}" ;;
    esp32-bt-hid) echo "${ESP32_BT_HID_STATUS}" ;;
    esp32-pokedex) echo "${ESP32_POKEDEX_STATUS}" ;;
    cypher-desk) echo "${CYPHER_DESK_STATUS}" ;;
    flock-you) echo "${FLOCK_YOU_STATUS}" ;;
    wiretap-32-cardputer) echo "${WIRETAP_STATUS}" ;;
    drone-mesh-mapper) echo "${DRONE_MESH_MAPPER_STATUS}" ;;
    cypher-airtag) echo "${CYPHER_AIRTAG_STATUS}" ;;
    bitcoin-card-wallet) echo "${BITCOIN_CARD_WALLET_STATUS}" ;;
    cardputer-game-station-emulators) echo "${CARDPUTER_GAME_STATION_EMULATORS_STATUS}" ;;
    esp32-bit-pirate) echo "${ESP32_BIT_PIRATE_STATUS}" ;;
    esp32-usb-stick) echo "${ESP32_USB_STICK_STATUS}" ;;
    news-reader) echo "${NEWS_READER_STATUS}" ;;
    open-wifi-scanner) echo "${OPEN_WIFI_SCANNER_STATUS}" ;;
    password-manager) echo "${PASSWORD_MANAGER_STATUS}" ;;
    ultimate-remote) echo "${ULTIMATE_REMOTE_STATUS}" ;;
    cardputer-game-os-games) echo "${GAME_OS_STATUS}" ;;
  esac
}

should_build() {
  local slug="$1"
  [[ -z "${REQUESTED_APP}" || "${REQUESTED_APP}" == "${slug}" ]]
}

run_build() {
  local slug="$1"
  local fn="$2"
  if ! should_build "${slug}"; then
    set_status "${slug}" "skipped"
    return 0
  fi
  "${fn}" || mark_failed "${slug}"
}

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

build_bundle_app() {
  local slug="$1"
  local folder="$2"
  local profile="$3"
  local dest="$4"
  local src="${CARDPUTER_APP_BUNDLE_ROOT}/${folder}"
  local out="${BUILD_ROOT}/${slug}"
  shift 4

  require_dir "${folder} source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building ${slug}"
  (
    cd "${src}"
    arduino-cli compile \
    --profile "${profile}" \
    --build-path "${out}" \
    --build-property "compiler.cpp.extra_flags=-I${CARDPUTER_APP_BUNDLE_ROOT}/shared" \
    "$@" \
      .
  ) || return 1
  copy_app_bin "${out}" "${dest}" || return 1
  set_status "${slug}" "ready"
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

build_cypher_pn532() {
  local src="${CYPHER_PN532_ROOT}/CardputerPN532"
  local out="${BUILD_ROOT}/cypher-pn532"
  require_dir "cypher-pn532 Cardputer source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building cypher-pn532"
  arduino-cli compile --fqbn "${CARDPUTER_FQBN}" --library "${RETURN_LIB}" --output-dir "${out}" "${src}" || return 1
  copy_app_bin "${out}" "cypher-pn532.bin" || return 1
  CYPHER_PN532_STATUS="ready"
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

build_esp32_bt_hid() {
  local src="${ESP32_BT_HID_ROOT}"
  local out="${BUILD_ROOT}/esp32-bt-hid"
  require_dir "ESP32_BT_HID source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building esp32-bt-hid"
  arduino-cli compile \
    --profile cardputer \
    --output-dir "${out}" \
    --build-property "compiler.cpp.extra_flags=-I${RETURN_LIB}/src" \
    "${src}" || return 1
  copy_app_bin "${out}" "esp32-bt-hid.bin" || return 1
  ESP32_BT_HID_STATUS="ready"
}

build_esp32_pokedex() {
  local src="${ESP32_POKEDEX_ROOT}"
  local out="${BUILD_ROOT}/esp32-pokedex"
  require_dir "esp32-pokedex source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building esp32-pokedex"
  arduino-cli compile \
    --profile cardputer \
    --output-dir "${out}" \
    --build-property "compiler.cpp.extra_flags=-I${RETURN_LIB}/src" \
    "${src}" || return 1
  copy_app_bin "${out}" "esp32-pokedex.bin" || return 1
  ESP32_POKEDEX_STATUS="ready"
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

build_drone_mesh_mapper() {
  local src="${DRONE_MESH_MAPPER_ROOT}/firmware/drone_mesh_mapper"
  local out="${BUILD_ROOT}/drone-mesh-mapper"
  require_dir "drone-mesh-mapper Cardputer source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building drone-mesh-mapper"
  arduino-cli compile \
    --profile cardputer_adv \
    --output-dir "${out}" \
    --build-property "compiler.cpp.extra_flags=-DBOARD_PROFILE_CARDPUTER_ADV -I${RETURN_LIB}/src" \
    "${src}" || return 1
  copy_app_bin "${out}" "drone-mesh-mapper.bin" || return 1
  DRONE_MESH_MAPPER_STATUS="ready"
}

build_cypher_airtag() {
  local src="${CYPHER_AIRTAG_ROOT}"
  local out="${BUILD_ROOT}/cypher-airtag"
  require_dir "cypher-airtag source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building cypher-airtag"
  arduino-cli compile \
    --profile cardputer-adv \
    --output-dir "${out}" \
    --build-property "compiler.cpp.extra_flags=-I${RETURN_LIB}/src" \
    "${src}" || return 1
  copy_app_bin "${out}" "cypher-airtag.bin" || return 1
  CYPHER_AIRTAG_STATUS="ready"
}

build_bitcoin_card_wallet() {
  build_bundle_app "bitcoin-card-wallet" "Bitcoin-Card-Wallet" "cardputer" "bitcoin-card-wallet.bin" \
    --build-property "compiler.c.elf.extra_flags=-Wl,-zmuldefs"
}

build_cardputer_game_station_emulators() {
  build_bundle_app "cardputer-game-station-emulators" "Cardputer-Game-Station-Emulators" "cardputer" "cardputer-game-station-emulators.bin" \
    --build-property "compiler.c.elf.extra_flags=-Wl,-zmuldefs -Wl,--wrap=bmp_create -Wl,--wrap=bmp_destroy"
}

build_esp32_bit_pirate() {
  build_bundle_app "esp32-bit-pirate" "ESP32-Bit-Pirate" "cardputer-adv" "esp32-bit-pirate.bin" \
    --build-property "compiler.c.elf.extra_flags=-Wl,-zmuldefs"
}

build_esp32_usb_stick() {
  build_bundle_app "esp32-usb-stick" "Esp32-USB-Stick" "cardputer" "esp32-usb-stick.bin"
}

build_news_reader() {
  build_bundle_app "news-reader" "News-Reader" "cardputer" "news-reader.bin"
}

build_open_wifi_scanner() {
  build_bundle_app "open-wifi-scanner" "Open-Wifi-Scanner" "cardputer" "open-wifi-scanner.bin"
}

build_password_manager() {
  build_bundle_app "password-manager" "Password-Manager" "cardputer" "password-manager.bin"
}

build_ultimate_remote() {
  build_bundle_app "ultimate-remote" "Ultimate-Remote" "cardputer-adv" "ultimate-remote.bin"
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
    cypher-pn532) CYPHER_PN532_STATUS="build_failed" ;;
    cypher-chat) CYPHER_CHAT_STATUS="build_failed" ;;
    cypher-drive) CYPHER_DRIVE_STATUS="build_failed" ;;
    esp32-bt-hid) ESP32_BT_HID_STATUS="build_failed" ;;
    esp32-pokedex) ESP32_POKEDEX_STATUS="build_failed" ;;
    cypher-desk) CYPHER_DESK_STATUS="build_failed" ;;
    flock-you) FLOCK_YOU_STATUS="build_failed" ;;
    wiretap-32-cardputer) WIRETAP_STATUS="build_failed" ;;
    drone-mesh-mapper) DRONE_MESH_MAPPER_STATUS="build_failed" ;;
    cypher-airtag) CYPHER_AIRTAG_STATUS="build_failed" ;;
    bitcoin-card-wallet) BITCOIN_CARD_WALLET_STATUS="build_failed" ;;
    cardputer-game-station-emulators) CARDPUTER_GAME_STATION_EMULATORS_STATUS="build_failed" ;;
    esp32-bit-pirate) ESP32_BIT_PIRATE_STATUS="build_failed" ;;
    esp32-usb-stick) ESP32_USB_STICK_STATUS="build_failed" ;;
    news-reader) NEWS_READER_STATUS="build_failed" ;;
    open-wifi-scanner) OPEN_WIFI_SCANNER_STATUS="build_failed" ;;
    password-manager) PASSWORD_MANAGER_STATUS="build_failed" ;;
    ultimate-remote) ULTIMATE_REMOTE_STATUS="build_failed" ;;
    cardputer-game-os-games) GAME_OS_STATUS="build_failed" ;;
  esac
}

run_build "cardputer-games" build_cardputer_games
run_build "cardputer-mpc" build_cardputer_mpc
run_build "cardputer-tarot" build_cardputer_tarot
run_build "cypher-pn532" build_cypher_pn532
run_build "cypher-chat" build_cypher_chat
run_build "cypher-drive" build_cypher_drive
run_build "esp32-bt-hid" build_esp32_bt_hid
run_build "esp32-pokedex" build_esp32_pokedex
run_build "cypher-desk" build_cypher_desk
run_build "flock-you" build_flock_you
run_build "wiretap-32-cardputer" build_wiretap
run_build "drone-mesh-mapper" build_drone_mesh_mapper
run_build "cypher-airtag" build_cypher_airtag
run_build "bitcoin-card-wallet" build_bitcoin_card_wallet
run_build "cardputer-game-station-emulators" build_cardputer_game_station_emulators
run_build "esp32-bit-pirate" build_esp32_bit_pirate
run_build "esp32-usb-stick" build_esp32_usb_stick
run_build "news-reader" build_news_reader
run_build "open-wifi-scanner" build_open_wifi_scanner
run_build "password-manager" build_password_manager
run_build "ultimate-remote" build_ultimate_remote
run_build "cardputer-game-os-games" build_game_os_games

CARDPUTER_GAMES_STATUS="${CARDPUTER_GAMES_STATUS}" \
CARDPUTER_MPC_STATUS="${CARDPUTER_MPC_STATUS}" \
CARDPUTER_TAROT_STATUS="${CARDPUTER_TAROT_STATUS}" \
CYPHER_PN532_STATUS="${CYPHER_PN532_STATUS}" \
CYPHER_CHAT_STATUS="${CYPHER_CHAT_STATUS}" \
CYPHER_DRIVE_STATUS="${CYPHER_DRIVE_STATUS}" \
ESP32_BT_HID_STATUS="${ESP32_BT_HID_STATUS}" \
ESP32_POKEDEX_STATUS="${ESP32_POKEDEX_STATUS}" \
CYPHER_DESK_STATUS="${CYPHER_DESK_STATUS}" \
FLOCK_YOU_STATUS="${FLOCK_YOU_STATUS}" \
WIRETAP_STATUS="${WIRETAP_STATUS}" \
DRONE_MESH_MAPPER_STATUS="${DRONE_MESH_MAPPER_STATUS}" \
CYPHER_AIRTAG_STATUS="${CYPHER_AIRTAG_STATUS}" \
BITCOIN_CARD_WALLET_STATUS="${BITCOIN_CARD_WALLET_STATUS}" \
CARDPUTER_GAME_STATION_EMULATORS_STATUS="${CARDPUTER_GAME_STATION_EMULATORS_STATUS}" \
ESP32_BIT_PIRATE_STATUS="${ESP32_BIT_PIRATE_STATUS}" \
ESP32_USB_STICK_STATUS="${ESP32_USB_STICK_STATUS}" \
NEWS_READER_STATUS="${NEWS_READER_STATUS}" \
OPEN_WIFI_SCANNER_STATUS="${OPEN_WIFI_SCANNER_STATUS}" \
PASSWORD_MANAGER_STATUS="${PASSWORD_MANAGER_STATUS}" \
ULTIMATE_REMOTE_STATUS="${ULTIMATE_REMOTE_STATUS}" \
GAME_OS_STATUS="${GAME_OS_STATUS}" \
CARDPUTER_GAMES_ROOT="${CARDPUTER_GAMES_ROOT}" \
CARDPUTER_MPC_ROOT="${CARDPUTER_MPC_ROOT}" \
CARDPUTER_TAROT_ROOT="${CARDPUTER_TAROT_ROOT}" \
CYPHER_PN532_ROOT="${CYPHER_PN532_ROOT}" \
CYPHER_CHAT_ROOT="${CYPHER_CHAT_ROOT}" \
CYPHER_DRIVE_ROOT="${CYPHER_DRIVE_ROOT}" \
ESP32_BT_HID_ROOT="${ESP32_BT_HID_ROOT}" \
ESP32_POKEDEX_ROOT="${ESP32_POKEDEX_ROOT}" \
CYPHER_DESK_ROOT="${CYPHER_DESK_ROOT}" \
FLOCK_YOU_ROOT="${FLOCK_YOU_ROOT}" \
WIRETAP_ROOT="${WIRETAP_ROOT}" \
DRONE_MESH_MAPPER_ROOT="${DRONE_MESH_MAPPER_ROOT}" \
CYPHER_AIRTAG_ROOT="${CYPHER_AIRTAG_ROOT}" \
CARDPUTER_APP_BUNDLE_ROOT="${CARDPUTER_APP_BUNDLE_ROOT}" \
GAME_OS_ROOT="${GAME_OS_ROOT}" \
CYPHER_OS_RELEASE_VERSION="${CYPHER_OS_RELEASE_VERSION:-local}" \
python3 "${ROOT}/tools/build-report.py" \
  --catalog "${CATALOG}" \
  --dist "${DIST}" \
  --game-manifest "${GAME_OS_MANIFEST}" \
  --report "${REPORT}" \
  --selected "${REQUESTED_APP}"

python3 "${ROOT}/tools/validate-catalog.py" "${CATALOG}" --manifest "${DIST}/apps.json" --dist "${DIST}"

failed=0
if [[ -n "${REQUESTED_APP}" ]]; then
  if [[ "$(get_status "${REQUESTED_APP}")" != "ready" ]]; then
    failed=1
  fi
elif [[ "${CARDPUTER_GAMES_STATUS}" != "ready" || "${CARDPUTER_MPC_STATUS}" != "ready" || "${CARDPUTER_TAROT_STATUS}" != "ready" || "${CYPHER_PN532_STATUS}" != "ready" || "${CYPHER_CHAT_STATUS}" != "ready" || "${CYPHER_DRIVE_STATUS}" != "ready" || "${ESP32_BT_HID_STATUS}" != "ready" || "${ESP32_POKEDEX_STATUS}" != "ready" || "${CYPHER_DESK_STATUS}" != "ready" || "${FLOCK_YOU_STATUS}" != "ready" || "${WIRETAP_STATUS}" != "ready" || "${DRONE_MESH_MAPPER_STATUS}" != "ready" || "${CYPHER_AIRTAG_STATUS}" != "ready" || "${BITCOIN_CARD_WALLET_STATUS}" != "ready" || "${CARDPUTER_GAME_STATION_EMULATORS_STATUS}" != "ready" || "${ESP32_BIT_PIRATE_STATUS}" != "ready" || "${ESP32_USB_STICK_STATUS}" != "ready" || "${NEWS_READER_STATUS}" != "ready" || "${OPEN_WIFI_SCANNER_STATUS}" != "ready" || "${PASSWORD_MANAGER_STATUS}" != "ready" || "${ULTIMATE_REMOTE_STATUS}" != "ready" || "${GAME_OS_STATUS}" != "ready" ]]; then
  failed=1
fi

if [[ "${failed}" -ne 0 ]]; then
  echo "[apps] one or more ready apps failed to build"
  exit 1
fi
