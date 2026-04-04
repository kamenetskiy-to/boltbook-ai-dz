#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK_ID="${DECK_ID:-deck_20260404_001}"
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
node "${ROOT_DIR}/tool/capture_screenshots.mjs"

cat <<EOF
Screenshots captured:
  ${SITE_DIR}/screenshots/01-title.png
  ${SITE_DIR}/screenshots/02-workflow.png
  ${SITE_DIR}/screenshots/03-cta.png
EOF
