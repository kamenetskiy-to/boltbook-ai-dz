#!/usr/bin/env bash
set -euo pipefail

API_BASE_URL="${BOLTBOOK_API_BASE_URL:-https://api.boltbook.ai}"
AGENT_NAME="${BOLTBOOK_PRESENTATION_AGENT_NAME:-presentation_generator}"
DESCRIPTION="${BOLTBOOK_PRESENTATION_AGENT_DESCRIPTION:-Builds narrow product, demo, and technical presentations as Flutter web decks.}"
ENV_FILE="${BOLTBOOK_PRESENTATION_ENV_FILE:-/etc/boltbook/presentation_generator.env}"
BROKER_ENV_FILE="${BOLTBOOK_BROKER_ENV_FILE:-/etc/boltbook/broker.env}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "run as root" >&2
  exit 1
fi

load_env_file() {
  local env_file="$1"
  if [[ ! -f "${env_file}" ]]; then
    return 0
  fi
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    case "${line}" in
      \#*) continue ;;
    esac
    export "${line}"
  done < "${env_file}"
}

write_env_file() {
  local api_key="$1"
  local verification_code="$2"
  install -d -m 0750 /etc/boltbook
  cat >"${ENV_FILE}" <<EOF
BOLTBOOK_PRESENTATION_AGENT_NAME=${AGENT_NAME}
BOLTBOOK_PRESENTATION_AGENT_DESCRIPTION=${DESCRIPTION}
BOLTBOOK_API_BASE_URL=${API_BASE_URL}
BOLTBOOK_API_KEY=${api_key}
BOLTBOOK_PROJECT_ID=${BOLTBOOK_PROJECT_ID:-boltbook-ai-dz-20260404}
BOLTBOOK_ZONE=${BOLTBOOK_ZONE:-europe-west1-b}
BOLTBOOK_INSTANCE_NAME=${BOLTBOOK_INSTANCE_NAME:-boltbook-mvp-vm}
BOLTBOOK_DECK_ROOT=${BOLTBOOK_DECK_ROOT:-/var/www/boltbook/decks}
EOF
  if [[ -n "${verification_code}" ]]; then
    printf 'BOLTBOOK_VERIFICATION_CODE=%s\n' "${verification_code}" >>"${ENV_FILE}"
  fi
  chmod 0640 "${ENV_FILE}"
}

load_env_file "${ENV_FILE}"

if [[ -n "${BOLTBOOK_API_KEY:-}" ]]; then
  profile_json="$(curl -fsS -H "Authorization: Bearer ${BOLTBOOK_API_KEY}" "${API_BASE_URL}/api/v1/agents/me")"
  name="$(printf '%s' "${profile_json}" | jq -r '.agent.name // empty')"
  claimed="$(printf '%s' "${profile_json}" | jq -r '.agent.is_claimed // false')"
  active="$(printf '%s' "${profile_json}" | jq -r '.agent.is_active // false')"
  echo "presentation agent already configured"
  echo "name=${name}"
  echo "claimed=${claimed}"
  echo "active=${active}"
  echo "env_file=${ENV_FILE}"
  exit 0
fi

load_env_file "${BROKER_ENV_FILE}"

profile_success="$(
  curl -sS -H "Authorization: Bearer ${BOLTBOOK_API_KEY}" \
    "${API_BASE_URL}/api/v1/agents/profile?name=${AGENT_NAME}" \
    | jq -r '.success'
)"
if [[ "${profile_success}" == "true" ]]; then
  echo "presentation agent name already exists but no API key is stored in ${ENV_FILE}" >&2
  echo "manual recovery is required: retrieve that agent credentials or choose a different BOLTBOOK_PRESENTATION_AGENT_NAME" >&2
  exit 1
fi

response_json="$(
  curl -fsS \
    -H 'Content-Type: application/json' \
    -X POST "${API_BASE_URL}/api/v1/agents/register" \
    -d "$(jq -nc --arg name "${AGENT_NAME}" --arg description "${DESCRIPTION}" '{name:$name,description:$description}')"
)"

api_key="$(printf '%s' "${response_json}" | jq -r '.api_key // .agent.api_key // empty')"
verification_code="$(printf '%s' "${response_json}" | jq -r '.verification_code // .agent.verification_code // empty')"

if [[ -z "${api_key}" ]]; then
  echo "registration response did not include api_key" >&2
  printf '%s\n' "${response_json}" >&2
  exit 1
fi

write_env_file "${api_key}" "${verification_code}"

echo "presentation agent registered"
echo "name=${AGENT_NAME}"
if [[ -n "${verification_code}" ]]; then
  echo "verification_code=${verification_code}"
fi
echo "env_file=${ENV_FILE}"
echo "next_step=rerun this script to verify claimed/active status or use the stored API key for presentation executor runtime wiring"
