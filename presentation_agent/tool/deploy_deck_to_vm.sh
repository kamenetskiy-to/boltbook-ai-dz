#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK_ID="${DECK_ID:-deck}"
PROJECT_ID="${PROJECT_ID:-boltbook-ai-dz-20260404}"
ZONE="${ZONE:-europe-west1-b}"
INSTANCE_NAME="${INSTANCE_NAME:-boltbook-mvp-vm}"
ARTIFACT_DIR="${ARTIFACT_DIR:-${ROOT_DIR}/build/decks/${DECK_ID}}"
SITE_DIR="${ARTIFACT_DIR}/site"
FIREWALL_RULE="${FIREWALL_RULE:-boltbook-decks-8080}"
INSTANCE_TAG="${INSTANCE_TAG:-boltbook-decks}"

"${ROOT_DIR}/tool/review_deck.sh"

EXTERNAL_IP="$(
  gcloud compute instances describe "${INSTANCE_NAME}" \
    --project "${PROJECT_ID}" \
    --zone "${ZONE}" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
)"

CANONICAL_URL="http://${EXTERNAL_IP}:8080/deck"
ASSET_BASE_URL="http://${EXTERNAL_IP}:8080/deck-assets/"
BASE_HREF="/deck-assets/"

python3 - "${SITE_DIR}/index.html" "${BASE_HREF}" <<'PY'
from pathlib import Path
import sys

index_path = Path(sys.argv[1])
base_href = sys.argv[2]
content = index_path.read_text()
content = content.replace('<base href="/">', f'<base href="{base_href}">')
index_path.write_text(content)
PY

python3 - "${SITE_DIR}" "${CANONICAL_URL}" "${ASSET_BASE_URL}" <<'PY'
import json
import pathlib
import sys

site_dir = pathlib.Path(sys.argv[1])
canonical_url = sys.argv[2]
asset_base_url = sys.argv[3]

manifest_path = site_dir / "manifest.json"
run_trace_path = site_dir / "run_trace.json"
screenshots = sorted((site_dir / "screenshots").glob("*.png"))
relative_screenshots = [f"{asset_base_url}screenshots/{path.name}" for path in screenshots]

manifest = json.loads(manifest_path.read_text())
manifest["status"] = "completed"
manifest["canonical_web_url"] = canonical_url
manifest["artifact_urls"] = {
    "web": canonical_url,
    "manifest": f"{asset_base_url}manifest.json",
    "run_trace": f"{asset_base_url}run_trace.json",
    "scene_plan": f"{asset_base_url}scene_plan.json",
    "narrative_brief": f"{asset_base_url}narrative_brief.json",
    "screenshot_critique": f"{asset_base_url}screenshot_critique.json",
}
manifest["screenshots"] = relative_screenshots
manifest["summary"] = "Сгенерирована и опубликована финальная русскоязычная презентация с обязательным сценарным планом, проверкой кадра и каноническим адресом /deck."
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")

run_trace = json.loads(run_trace_path.read_text())
run_trace["status"] = "completed"
run_trace["canonical_web_url"] = canonical_url
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
ROOT_INDEX_UPLOAD="~/boltbook-root-index.html"
SERVER_SCRIPT_UPLOAD="~/serve_decks.py"

gcloud compute scp --recurse "${SITE_DIR}" "${INSTANCE_NAME}:${TEMP_UPLOAD}" \
  --project "${PROJECT_ID}" \
  --zone "${ZONE}"

gcloud compute scp "${ROOT_DIR}/../deploy/systemd/boltbook-decks.service" "${INSTANCE_NAME}:${SERVICE_UPLOAD}" \
  --project "${PROJECT_ID}" \
  --zone "${ZONE}"

cat > /tmp/boltbook-root-index.html <<EOF
<!doctype html>
<html lang="ru">
  <head>
    <meta charset="utf-8" />
    <meta http-equiv="refresh" content="0; url=/deck" />
    <title>Boltbook Deck</title>
  </head>
  <body>
    <a href="/deck">Перейти к финальной презентации</a>
  </body>
</html>
EOF

gcloud compute scp /tmp/boltbook-root-index.html "${INSTANCE_NAME}:${ROOT_INDEX_UPLOAD}" \
  --project "${PROJECT_ID}" \
  --zone "${ZONE}"

gcloud compute scp "${ROOT_DIR}/../deploy/vm/serve_decks.py" "${INSTANCE_NAME}:${SERVER_SCRIPT_UPLOAD}" \
  --project "${PROJECT_ID}" \
  --zone "${ZONE}"

gcloud compute ssh "${INSTANCE_NAME}" \
  --project "${PROJECT_ID}" \
  --zone "${ZONE}" \
  --command "sudo rm -rf /var/www/boltbook/deck /var/www/boltbook/deck-assets /var/www/boltbook/decks && sudo install -d -o root -g root /var/www/boltbook/deck-assets /usr/local/lib/boltbook && sudo rsync -a --delete ${TEMP_UPLOAD}/ /var/www/boltbook/deck-assets/ && sudo install -D -m 0644 ${ROOT_INDEX_UPLOAD} /var/www/boltbook/index.html && sudo install -D -m 0755 ${SERVER_SCRIPT_UPLOAD} /usr/local/lib/boltbook/serve_decks.py && sudo install -D -m 0644 ${SERVICE_UPLOAD} /etc/systemd/system/boltbook-decks.service && sudo systemctl daemon-reload && sudo systemctl enable boltbook-decks.service && sudo systemctl restart boltbook-decks.service && rm -rf ${TEMP_UPLOAD} ${SERVICE_UPLOAD} ${ROOT_INDEX_UPLOAD} ${SERVER_SCRIPT_UPLOAD}"

rm -f /tmp/boltbook-root-index.html

for url in \
  "${CANONICAL_URL}" \
  "${ASSET_BASE_URL}manifest.json" \
  "${ASSET_BASE_URL}run_trace.json" \
  "${ASSET_BASE_URL}scene_plan.json" \
  "${ASSET_BASE_URL}narrative_brief.json" \
  "${ASSET_BASE_URL}screenshot_critique.json"
do
  http_code="$(curl -s -o /dev/null -w '%{http_code}' "${url}")"
  if [[ "${http_code}" != "200" ]]; then
    echo "deployment validation failed for ${url}: HTTP ${http_code}" >&2
    exit 1
  fi
done

cat <<EOF
Deck deployed:
  deck_id: ${DECK_ID}
  url: ${CANONICAL_URL}
EOF
