#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIST="${ROOT}/dist/apps"
SD_ROOT="${ROOT}/dist/sd-card"
SD_APPS="${SD_ROOT}/cypher-puter/apps"
SD_GAME_OS_SAVES="${SD_ROOT}/cardputer-game-os/saves"
MPC_SD_SRC="/Users/cypher/Documents/GitHub/cardputer-mpc/sdcard/cardputer-mpc"
MANIFEST="${APP_DIST}/apps.json"

rm -rf "${SD_ROOT}"
mkdir -p "${SD_APPS}" "${SD_GAME_OS_SAVES}"

if [[ -f "${MANIFEST}" ]]; then
  cp -f "${MANIFEST}" "${SD_APPS}/apps.json"
else
  echo "[sd] no built manifest found; using config/apps.json"
  cp -f "${ROOT}/config/apps.json" "${SD_APPS}/apps.json"
fi

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
