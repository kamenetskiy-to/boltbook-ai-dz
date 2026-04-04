#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK_ID="${DECK_ID:-deck_20260404_001}"
PROJECT_ID="${PROJECT_ID:-boltbook-ai-dz-20260404}"
ZONE="${ZONE:-europe-west1-b}"
INSTANCE_NAME="${INSTANCE_NAME:-boltbook-mvp-vm}"
ARTIFACT_DIR="${ARTIFACT_DIR:-${ROOT_DIR}/build/decks/${DECK_ID}}"
SITE_DIR="${ARTIFACT_DIR}/site"
FIREWALL_RULE="${FIREWALL_RULE:-boltbook-decks-8080}"
INSTANCE_TAG="${INSTANCE_TAG:-boltbook-decks}"

"${ROOT_DIR}/tool/capture_screenshots.sh"

EXTERNAL_IP="$(
  gcloud compute instances describe "${INSTANCE_NAME}" \
    --project "${PROJECT_ID}" \
    --zone "${ZONE}" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
)"

BASE_URL="http://${EXTERNAL_IP}:8080/decks/${DECK_ID}/"
BASE_HREF="/decks/${DECK_ID}/"

python3 - "${SITE_DIR}/index.html" "${BASE_HREF}" <<'PY'
from pathlib import Path
import sys

index_path = Path(sys.argv[1])
base_href = sys.argv[2]
content = index_path.read_text()
content = content.replace('<base href="/">', f'<base href="{base_href}">')
index_path.write_text(content)
PY

python3 - "${SITE_DIR}" "${BASE_URL}" <<'PY'
import json
import pathlib
import sys

site_dir = pathlib.Path(sys.argv[1])
base_url = sys.argv[2]

manifest_path = site_dir / "manifest.json"
run_trace_path = site_dir / "run_trace.json"

manifest = json.loads(manifest_path.read_text())
manifest["status"] = "completed"
manifest["artifact_urls"] = {
    "web": base_url,
    "manifest": f"{base_url}manifest.json",
}
manifest["screenshots"] = [
    f"{base_url}screenshots/01-title.png",
    f"{base_url}screenshots/02-workflow.png",
    f"{base_url}screenshots/03-cta.png",
]
manifest["summary"] = "Generated and deployed a reviewer-facing Flutter web deck with validation screenshots."
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")

run_trace = json.loads(run_trace_path.read_text())
run_trace["status"] = "completed"
run_trace["artifact_urls"] = manifest["artifact_urls"]
run_trace["screenshots"] = manifest["screenshots"]
run_trace_path.write_text(json.dumps(run_trace, indent=2) + "\n")
PY

if ! gcloud compute firewall-rules describe "${FIREWALL_RULE}" --project "${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud compute firewall-rules create "${FIREWALL_RULE}" \
    --project "${PROJECT_ID}" \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:8080 \
    --target-tags="${INSTANCE_TAG}" \
    --source-ranges=0.0.0.0/0
fi

gcloud compute instances add-tags "${INSTANCE_NAME}" \
  --project "${PROJECT_ID}" \
  --zone "${ZONE}" \
  --tags="${INSTANCE_TAG}"

TEMP_UPLOAD="~/deck-${DECK_ID}"
SERVICE_UPLOAD="~/boltbook-decks.service"

gcloud compute scp --recurse "${SITE_DIR}" "${INSTANCE_NAME}:${TEMP_UPLOAD}" \
  --project "${PROJECT_ID}" \
  --zone "${ZONE}"

gcloud compute scp "${ROOT_DIR}/../deploy/systemd/boltbook-decks.service" "${INSTANCE_NAME}:${SERVICE_UPLOAD}" \
  --project "${PROJECT_ID}" \
  --zone "${ZONE}"

gcloud compute ssh "${INSTANCE_NAME}" \
  --project "${PROJECT_ID}" \
  --zone "${ZONE}" \
  --command "sudo install -d -o root -g root /var/www/boltbook/decks/${DECK_ID} && sudo rsync -a --delete ${TEMP_UPLOAD}/ /var/www/boltbook/decks/${DECK_ID}/ && sudo install -D -m 0644 ${SERVICE_UPLOAD} /etc/systemd/system/boltbook-decks.service && sudo systemctl daemon-reload && sudo systemctl enable --now boltbook-decks.service && rm -rf ${TEMP_UPLOAD} ${SERVICE_UPLOAD}"

cat <<EOF
Deck deployed:
  deck_id: ${DECK_ID}
  url: ${BASE_URL}
EOF
