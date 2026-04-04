#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REMOTE="${REMOTE:-large}"
REMOTE_REPO="${REMOTE_REPO:-/opt/meta-interpreter}"
SERVICE_NAME="${SERVICE_NAME:-ttc-runtime-sse.service}"
REMOTE_SERVICE="/etc/systemd/system/${SERVICE_NAME}"
LOCAL_SERVICE="${ROOT_DIR}/deploy/systemd/ttc-runtime-sse.service"
MEDIUM_IP="${MEDIUM_IP:-65.38.98.105}"

# Fano deployment points on large:
# - runtime_sse
# - future api_service
# - future admin_mcp

ssh "${REMOTE}" "mkdir -p '${REMOTE_REPO}'"
rsync -az --delete \
  --exclude '.git' \
  --exclude '.venv' \
  --exclude '__pycache__' \
  --exclude 'artifacts/narrative_frames' \
  "${ROOT_DIR}/" "${REMOTE}:${REMOTE_REPO}/"

ssh "${REMOTE}" "cd '${REMOTE_REPO}' && make build"
scp "${LOCAL_SERVICE}" "${REMOTE}:${REMOTE_SERVICE}"
ssh "${REMOTE}" "systemctl daemon-reload && systemctl enable --now '${SERVICE_NAME}' && systemctl restart '${SERVICE_NAME}'"
ssh "${REMOTE}" "if command -v ufw >/dev/null 2>&1; then ufw allow from '${MEDIUM_IP}' to any port 8000 proto tcp; fi"
