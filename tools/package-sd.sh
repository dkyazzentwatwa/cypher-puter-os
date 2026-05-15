#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_ROOT="${CYPHER_OS_WORKSPACE_ROOT:-$(cd "${ROOT}/.." && pwd)}"
APP_DIST="${ROOT}/dist/apps"
SD_ROOT="${ROOT}/dist/sd-card"
SD_APPS="${SD_ROOT}/cypher-puter/apps"
SD_GAME_OS_SAVES="${SD_ROOT}/cardputer-game-os/saves"
CARDPUTER_MPC_ROOT="${CYPHER_OS_CARDPUTER_MPC_DIR:-${WORKSPACE_ROOT}/cardputer-mpc}"
MPC_SD_SRC="${CARDPUTER_MPC_ROOT}/sdcard/cardputer-mpc"
MANIFEST="${APP_DIST}/apps.json"

if [[ ! -f "${MANIFEST}" ]]; then
  echo "[sd] missing ${MANIFEST}"
  echo "[sd] run ./tools/build-apps.sh before packaging the SD card"
  exit 1
fi

rm -rf "${SD_ROOT}"
mkdir -p "${SD_APPS}" "${SD_GAME_OS_SAVES}"

cp -f "${MANIFEST}" "${SD_APPS}/apps.json"

if compgen -G "${APP_DIST}/*.bin" >/dev/null; then
  cp -f "${APP_DIST}"/*.bin "${SD_APPS}/"
fi

if [[ -d "${MPC_SD_SRC}" ]]; then
  cp -R "${MPC_SD_SRC}" "${SD_ROOT}/"
else
  echo "[sd] warning: ${MPC_SD_SRC} missing; Cardputer MPC will use its fallback kit"
fi

echo "[sd] prepared ${SD_ROOT}"
echo "[sd] copy the contents of ${SD_ROOT} to the root of a FAT32 SD card"
