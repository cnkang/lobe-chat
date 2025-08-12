#!/usr/bin/env bash
set -euo pipefail
log(){ echo "[$(date +'%F %T')] $*"; }

APP_DIR="/opt/lobechat"
REGION="us-east-1"
SSM_PREFIX="/newswarrior/lobechat"

cd "$APP_DIR"

# 拉 SSM -> 写 .env（覆盖）
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

# 统一归属（确保 deploy/node_modules/.next 等都可读）
chown -R lobechat:lobechat "$APP_DIR"

# 产物自检（不做 bun install）
[ -d ".next" ] || echo "WARN: .next missing (consider standalone or check artifacts)"
[ -d "node_modules" ] || echo "WARN: node_modules missing (CodeBuild should package it)"
[ -f "package.json" ] || echo "WARN: package.json missing"

log "after_install.sh done"
