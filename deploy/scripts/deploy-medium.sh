#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REMOTE="${REMOTE:-medium}"
REMOTE_ROOT="${REMOTE_ROOT:-/var/www/universal-life-protocol}"
REMOTE_CURRENT="${REMOTE_ROOT}/current"
REMOTE_DEMO="${REMOTE_CURRENT}/demo"
SITE_NAME="${SITE_NAME:-universal-life-protocol.com.conf}"
BOOTSTRAP_CONF="${ROOT_DIR}/deploy/nginx/medium/universal-life-protocol.com.bootstrap.conf"
FINAL_CONF="${ROOT_DIR}/deploy/nginx/medium/universal-life-protocol.com.conf"
LE_EMAIL="${LE_EMAIL:-}"
CERTBOT_NAMES=(
  universallifeprotocol.com
  www.universallifeprotocol.com
  universal-life-protocol.com
  www.universal-life-protocol.com
  universallifeprotocol.store
  universallifeprotocol.io
  universallifeprotocol.net
)

# Fano deployment points on medium:
# - public_site
# - browser_projection
# - browser_narrative

ssh "${REMOTE}" "mkdir -p '${REMOTE_DEMO}'"
rsync -az --delete "${ROOT_DIR}/demo/" "${REMOTE}:${REMOTE_DEMO}/"
scp "${BOOTSTRAP_CONF}" "${REMOTE}:/etc/nginx/sites-available/${SITE_NAME}"
ssh "${REMOTE}" "ln -sfn '/etc/nginx/sites-available/${SITE_NAME}' '/etc/nginx/sites-enabled/${SITE_NAME}' && nginx -t && systemctl reload nginx"

if [[ -n "${LE_EMAIL}" ]]; then
  certbot_args=()
  for name in "${CERTBOT_NAMES[@]}"; do
    certbot_args+=(-d "${name}")
  done
  ssh "${REMOTE}" "certbot certonly --webroot -w '${REMOTE_DEMO}' --non-interactive --agree-tos -m '${LE_EMAIL}' ${certbot_args[*]}"
  scp "${FINAL_CONF}" "${REMOTE}:/etc/nginx/sites-available/${SITE_NAME}"
  ssh "${REMOTE}" "nginx -t && systemctl reload nginx"
else
  echo 'LE_EMAIL is not set; bootstrap HTTP config installed, TLS not requested.'
fi
