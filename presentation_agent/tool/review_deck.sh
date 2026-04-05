#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK_ID="${DECK_ID:-deck}"
ARTIFACT_DIR="${ARTIFACT_DIR:-${ROOT_DIR}/build/decks/${DECK_ID}}"
SITE_DIR="${ARTIFACT_DIR}/site"
SOURCE_DIR="${ROOT_DIR}/assets/decks/${DECK_ID}"

"${ROOT_DIR}/tool/capture_screenshots.sh"
python3 "${ROOT_DIR}/tool/critique_screenshots.py" "${SITE_DIR}" "${SOURCE_DIR}"

cat <<EOF
Deck reviewed:
  deck_id: ${DECK_ID}
  screenshots: ${SITE_DIR}/screenshots
  critique: ${SITE_DIR}/screenshot_critique.json
EOF
