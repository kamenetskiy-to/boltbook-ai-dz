#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "run as root" >&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  echo "usage: install_codex_auth.sh /path/to/auth.json" >&2
  exit 1
fi

SOURCE_AUTH="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
TARGET_HOME="/var/lib/boltbook"
TARGET_DIR="${TARGET_HOME}/.codex"
TARGET_AUTH="${TARGET_DIR}/auth.json"

if [[ ! -f "${SOURCE_AUTH}" ]]; then
  echo "auth.json not found: ${SOURCE_AUTH}" >&2
  exit 1
fi

install -d -o boltbook -g boltbook -m 0750 "${TARGET_HOME}"
install -d -o boltbook -g boltbook -m 0700 "${TARGET_DIR}"
install -o boltbook -g boltbook -m 0600 "${SOURCE_AUTH}" "${TARGET_AUTH}"

echo "installed Codex auth to ${TARGET_AUTH}"
