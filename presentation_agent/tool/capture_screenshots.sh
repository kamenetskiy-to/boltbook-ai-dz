#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK_ID="${DECK_ID:-deck}"
ARTIFACT_DIR="${ARTIFACT_DIR:-${ROOT_DIR}/build/decks/${DECK_ID}}"
SITE_DIR="${ARTIFACT_DIR}/site"
PORT="${PORT:-8123}"
CHROME_BIN="${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

"${ROOT_DIR}/tool/build_deck.sh"

if [[ ! -x "${CHROME_BIN}" ]]; then
  echo "chrome binary not found: ${CHROME_BIN}" >&2
  exit 1
fi

mkdir -p "${SITE_DIR}/screenshots"

python3 -m http.server "${PORT}" --directory "${SITE_DIR}" >/tmp/"${DECK_ID}"-http.log 2>&1 &
SERVER_PID=$!
trap 'kill "${SERVER_PID}" >/dev/null 2>&1 || true' EXIT
sleep 2

CHROME_BIN="${CHROME_BIN}" \
SCREENSHOT_BASE_URL="http://127.0.0.1:${PORT}" \
SCREENSHOT_OUTPUT_DIR="${SITE_DIR}/screenshots" \
SCREENSHOT_PLAN_FILE="${SITE_DIR}/presentation_plan.json" \
node "${ROOT_DIR}/tool/capture_screenshots.mjs"

echo "Screenshots captured:"
find "${SITE_DIR}/screenshots" -maxdepth 1 -type f -name '*.png' | sort | sed 's/^/  /'
