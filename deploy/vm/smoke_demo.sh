#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: smoke_demo.sh /path/to/release" >&2
  exit 1
fi

RELEASE_DIR="$(cd "$1" && pwd)"
DB_PATH="/var/lib/boltbook/smoke-demo.db"
LOG_PATH="/var/log/boltbook/demo-smoke.log"

rm -f "${DB_PATH}"
install -d -o boltbook -g boltbook /var/log/boltbook /var/lib/boltbook
touch "${LOG_PATH}"
chown boltbook:boltbook "${LOG_PATH}"

sudo -u boltbook env \
  PATH="/usr/local/go/bin:/usr/bin:/bin" \
  BOLTBOOK_CLIENT_MODE=fake \
  BOLTBOOK_DB_PATH="${DB_PATH}" \
  "${RELEASE_DIR}/bin/demo" | tee "${LOG_PATH}"

echo
echo "Run history:"
sqlite3 "${DB_PATH}" 'select component, status, examined, processed from run_history order by started_at;'
echo
echo "Transport actions:"
sqlite3 "${DB_PATH}" 'select attempted_mode, outcome, target_agent_name from transport_actions order by attempted_at;'
echo
echo "Fixer responses:"
sqlite3 "${DB_PATH}" 'select decision, response_mode from fixer_response_actions order by responded_at;'
