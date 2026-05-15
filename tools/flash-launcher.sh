#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${1:-}"

detect_port() {
  ls /dev/cu.usbmodem* 2>/dev/null | head -n 1 || true
}

if [[ -z "${PORT}" ]]; then
  PORT="$(detect_port)"
fi

if [[ -z "${PORT}" ]]; then
  echo "[flash] no /dev/cu.usbmodem* port found"
  echo "[flash] connect the Cardputer ADV, then run: arduino-cli board list"
  exit 1
fi

echo "[flash] current port: ${PORT}"
echo "[flash] touching 1200 baud before upload"
stty -f "${PORT}" 1200 || true
sleep 2

NEW_PORT="$(detect_port)"
if [[ -n "${NEW_PORT}" ]]; then
  PORT="${NEW_PORT}"
fi

echo "[flash] upload port: ${PORT}"
arduino-cli upload --profile adv -p "${PORT}" "${ROOT}"
echo "[flash] done"
