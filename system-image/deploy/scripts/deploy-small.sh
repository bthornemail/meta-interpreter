#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REMOTE="${REMOTE:-small}"
REMOTE_ROOT="${REMOTE_ROOT:-/var/www/universal-life-protocol-downloads}"
REMOTE_CURRENT="${REMOTE_ROOT}/current"
DOWNLOAD_SOURCE="${DOWNLOAD_SOURCE:-${ROOT_DIR}/artifacts}"
SITE_NAME="${SITE_NAME:-matroid-garden.com.conf}"
BOOTSTRAP_CONF="${ROOT_DIR}/nginx/small/artifact.small.universal-life-protocol.com.bootstrap.conf"
FINAL_CONF="${ROOT_DIR}/nginx/small/artifact.small.universal-life-protocol.com.conf"
LE_EMAIL="${LE_EMAIL:-}"

# Fano deployment point on small:
# - downloads

ssh "${REMOTE}" "mkdir -p '${REMOTE_CURRENT}'"
rsync -az --delete "${DOWNLOAD_SOURCE}/" "${REMOTE}:${REMOTE_CURRENT}/"
scp "${BOOTSTRAP_CONF}" "${REMOTE}:/etc/nginx/sites-available/${SITE_NAME}"
ssh "${REMOTE}" "ln -sfn '/etc/nginx/sites-available/${SITE_NAME}' '/etc/nginx/sites-enabled/${SITE_NAME}' && nginx -t && systemctl reload nginx"

if [[ -n "${LE_EMAIL}" ]]; then
  ssh "${REMOTE}" "certbot certonly --webroot -w '${REMOTE_CURRENT}' --non-interactive --agree-tos -m '${LE_EMAIL}' -d matroid-garden.com -d www.matroid-garden.com"
  scp "${FINAL_CONF}" "${REMOTE}:/etc/nginx/sites-available/${SITE_NAME}"
  ssh "${REMOTE}" "nginx -t && systemctl reload nginx"
else
  echo 'LE_EMAIL is not set; bootstrap HTTP config installed, TLS not requested.'
fi
