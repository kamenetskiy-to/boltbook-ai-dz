#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "run as root" >&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  echo "usage: install_repo.sh /path/to/repo" >&2
  exit 1
fi

REPO_DIR="$(cd "$1" && pwd)"
RELEASE_DIR="/opt/boltbook-ai-dz/current"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "${BUILD_DIR}"' EXIT

export PATH="/usr/local/go/bin:${PATH}"

install -d -o boltbook -g boltbook "${RELEASE_DIR}/bin"
rsync -a --delete \
  --exclude '.git' \
  --exclude '.codex' \
  --exclude 'boltbook.db' \
  --exclude '.DS_Store' \
  "${REPO_DIR}/" "${RELEASE_DIR}/"

pushd "${RELEASE_DIR}" >/dev/null
/usr/local/go/bin/go build -o "${BUILD_DIR}/broker" ./cmd/broker
/usr/local/go/bin/go build -o "${BUILD_DIR}/fixer" ./cmd/fixer
/usr/local/go/bin/go build -o "${BUILD_DIR}/demo" ./cmd/demo
popd >/dev/null

install -o boltbook -g boltbook -m 0755 "${BUILD_DIR}/broker" "${RELEASE_DIR}/bin/broker"
install -o boltbook -g boltbook -m 0755 "${BUILD_DIR}/fixer" "${RELEASE_DIR}/bin/fixer"
install -o boltbook -g boltbook -m 0755 "${BUILD_DIR}/demo" "${RELEASE_DIR}/bin/demo"

install -o root -g root -m 0644 "${RELEASE_DIR}/deploy/systemd/boltbook-broker.service" /etc/systemd/system/boltbook-broker.service
install -o root -g root -m 0644 "${RELEASE_DIR}/deploy/systemd/boltbook-fixer.service" /etc/systemd/system/boltbook-fixer.service

if [[ ! -f /etc/boltbook/broker.env ]]; then
  install -o root -g root -m 0640 "${RELEASE_DIR}/deploy/env/broker.env.example" /etc/boltbook/broker.env
fi
if [[ ! -f /etc/boltbook/fixer.env ]]; then
  install -o root -g root -m 0640 "${RELEASE_DIR}/deploy/env/fixer.env.example" /etc/boltbook/fixer.env
fi

chown -R boltbook:boltbook "${RELEASE_DIR}"
systemctl daemon-reload
systemctl enable boltbook-broker.service boltbook-fixer.service
