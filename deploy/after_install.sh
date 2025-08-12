#!/usr/bin/env bash
set -euo pipefail
log(){ echo "[$(date +'%F %T')] $*"; }

APP_DIR="/opt/lobechat"
REGION="us-east-1"
SSM_PREFIX="/newswarrior/lobechat"

cd "$APP_DIR"

log "==> Build .env from SSM ${SSM_PREFIX}"
: > .env
echo "NODE_ENV=production" >> .env

NEXT_TOKEN=""
while :; do
  if [ -z "${NEXT_TOKEN:-}" ]; then
    RESP=$(aws ssm get-parameters-by-path --path "${SSM_PREFIX}/" --with-decryption --recursive --region "$REGION" --output json)
  else
    RESP=$(aws ssm get-parameters-by-path --path "${SSM_PREFIX}/" --with-decryption --recursive --region "$REGION" --output json --starting-token "$NEXT_TOKEN")
  fi
  echo "$RESP" | jq -r '.Parameters[] | "\(.Name|split("/")[-1])=\(.Value)"' >> .env
  NEXT_TOKEN=$(echo "$RESP" | jq -r '.NextToken // empty')
  [ -z "$NEXT_TOKEN" ] && break
done

chown lobechat:lobechat .env
chmod 600 .env

# 统一归属，确保服务用户可读写产物
chown -R lobechat:lobechat "$APP_DIR"

# 轻量自检（standalone 只需要下面两块）
[ -f ".next/standalone/server.js" ] || { echo "ERROR: standalone server.js missing"; exit 1; }
[ -d ".next/static" ] || echo "WARN: .next/static missing"

log "after_install.sh done"
