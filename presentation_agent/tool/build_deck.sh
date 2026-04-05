#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK_ID="${DECK_ID:-deck_20260405_final_ru_001}"
ARTIFACT_DIR="${ARTIFACT_DIR:-${ROOT_DIR}/build/decks/${DECK_ID}}"
SITE_DIR="${ARTIFACT_DIR}/site"
SOURCE_DIR="${ROOT_DIR}/assets/decks/${DECK_ID}"

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "unknown deck id: ${DECK_ID}" >&2
  exit 1
fi

pushd "${ROOT_DIR}" >/dev/null
dart run tool/validate_deck.dart "${SOURCE_DIR}/presentation_plan.json"
flutter build web --release --dart-define=DECK_ID="${DECK_ID}"
popd >/dev/null

rm -rf "${ARTIFACT_DIR}"
mkdir -p "${SITE_DIR}/screenshots"

rsync -a "${ROOT_DIR}/build/web/" "${SITE_DIR}/"

for metadata_file in manifest.json presentation_plan.json run_trace.json sources.json; do
  cp "${SOURCE_DIR}/${metadata_file}" "${SITE_DIR}/${metadata_file}"
done

cat <<EOF
Deck artifact prepared:
  deck_id: ${DECK_ID}
  site_dir: ${SITE_DIR}
EOF
