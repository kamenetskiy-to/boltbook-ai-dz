#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "run as root" >&2
  exit 1
fi

GO_VERSION="${GO_VERSION:-1.25.4}"
ARCHIVE="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${ARCHIVE}"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl git rsync sqlite3 ca-certificates nodejs npm

if [[ ! -x /usr/local/go/bin/go ]] || [[ "$(/usr/local/go/bin/go version 2>/dev/null || true)" != *"go${GO_VERSION}"* ]]; then
  rm -rf /usr/local/go
  tmp_archive="/tmp/${ARCHIVE}"
  curl -fsSL "${GO_URL}" -o "${tmp_archive}"
  tar -C /usr/local -xzf "${tmp_archive}"
  rm -f "${tmp_archive}"
fi

if ! id -u boltbook >/dev/null 2>&1; then
  useradd --system --create-home --home-dir /home/boltbook --shell /bin/bash boltbook
fi

install -d -o boltbook -g boltbook /opt/boltbook-ai-dz/current
install -d -o boltbook -g boltbook /var/lib/boltbook
install -d -o boltbook -g boltbook /var/log/boltbook
install -d -o root -g root /etc/boltbook

cat >/etc/profile.d/go-local.sh <<'EOF'
export PATH=/usr/local/go/bin:$PATH
EOF

npm install -g @openai/codex

codex_path="$(command -v codex)"
if [[ -n "${codex_path}" && "${codex_path}" != "/usr/local/bin/codex" ]]; then
  ln -sf "${codex_path}" /usr/local/bin/codex
fi
