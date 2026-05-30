#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-${CYPHER_OS_RELEASE_VERSION:-local}}"
RELEASE_DIR="${ROOT}/dist/release"
LAUNCHER_DIR="${ROOT}/dist/launcher"
SD_ROOT="${ROOT}/dist/sd-card"
APP_MANIFEST="${SD_ROOT}/cypher-puter/apps/apps.json"

rm -rf "${RELEASE_DIR}"
mkdir -p "${RELEASE_DIR}"

export CYPHER_OS_RELEASE_VERSION="${VERSION}"

python3 "${ROOT}/tools/validate-catalog.py" "${ROOT}/config/apps.json"

"${ROOT}/tools/build-launcher.sh"

launcher_bin="$(find "${LAUNCHER_DIR}" -maxdepth 1 -type f -name "*.merged.bin" | head -n 1 || true)"
if [[ -z "${launcher_bin}" ]]; then
  launcher_bin="$(find "${LAUNCHER_DIR}" -maxdepth 1 -type f -name "*.ino.bin" | head -n 1 || true)"
fi
if [[ -z "${launcher_bin}" ]]; then
  echo "[release] launcher .merged.bin or .ino.bin missing in ${LAUNCHER_DIR}" >&2
  exit 1
fi
cp -f "${launcher_bin}" "${RELEASE_DIR}/cypher-os-launcher.bin"

"${ROOT}/tools/build-apps.sh"
"${ROOT}/tools/package-sd.sh"

python3 "${ROOT}/tools/validate-catalog.py" "${ROOT}/config/apps.json" --manifest "${APP_MANIFEST}" --dist "${SD_ROOT}/cypher-puter/apps"

(cd "${SD_ROOT}" && zip -qr "${RELEASE_DIR}/cypher-os-sd-card.zip" .)
cp -f "${APP_MANIFEST}" "${RELEASE_DIR}/apps.json"
cp -f "${ROOT}/dist/BUILD_REPORT.md" "${RELEASE_DIR}/BUILD_REPORT.md"

echo "[release] prepared ${RELEASE_DIR}"
echo "[release] assets:"
echo "  ${RELEASE_DIR}/cypher-os-launcher.bin"
echo "  ${RELEASE_DIR}/cypher-os-sd-card.zip"
echo "  ${RELEASE_DIR}/apps.json"
echo "  ${RELEASE_DIR}/BUILD_REPORT.md"
