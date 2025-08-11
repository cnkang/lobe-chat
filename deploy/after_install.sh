#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/lobechat"
REGION="us-east-1"
SSM_PREFIX="/newswarrior/lobechat/"

cd "$APP_DIR"

# 1) 从 SSM 拉取所有该前缀的参数，写入 .env（覆盖）
: > .env
echo "NODE_ENV=production" >> .env

NEXT_TOKEN=""
while :; do
  if [ -z "$NEXT_TOKEN" ]; then
    RESP=$(aws ssm get-parameters-by-path --path "$SSM_PREFIX" --with-decryption --recursive --region "$REGION" --output json)
  else
    RESP=$(aws ssm get-parameters-by-path --path "$SSM_PREFIX" --with-decryption --recursive --region "$REGION" --output json --starting-token "$NEXT_TOKEN")
  fi
  echo "$RESP" | jq -r '.Parameters[] | "\(.Name|split("/")[-1])=\(.Value)"' >> .env
  NEXT_TOKEN=$(echo "$RESP" | jq -r '.NextToken // empty')
  [ -z "$NEXT_TOKEN" ] && break
done

chown lobechat:lobechat .env
chmod 600 .env

# 2) 安装依赖（如需；若 node_modules 已随 artifact 打包，可跳过）
su -s /bin/bash - lobechat -c 'export BUN_INSTALL=/home/lobechat/.bun; export PATH=/home/lobechat/.bun/bin:$PATH; if [ ! -d node_modules ] || [ ! -f bun.lockb ]; then bun install --no-progress; fi'
