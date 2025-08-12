#!/usr/bin/env bash
set -euo pipefail
log(){ echo "[$(date +'%F %T')] $*"; }

APP_DIR="/opt/lobechat"
REGION="us-east-1"
SSM_PREFIX="/newswarrior/lobechat"
BUN_HOME="${APP_DIR}/.bun"
BUN_BIN="${BUN_HOME}/bin/bun"

cd "$APP_DIR"

# 1) 拉 SSM -> 写 .env（覆盖）
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
chown lobechat:lobechat .env && chmod 600 .env

# 2) 校验构建产物是否存在（防止空目录导致启动失败）
[ -d ".next" ] || { echo "ERROR: .next not found"; exit 1; }
[ -d "node_modules" ] || { echo "ERROR: node_modules not found (install must happen in CodeBuild)"; exit 1; }
[ -f "package.json" ] || { echo "ERROR: package.json missing"; exit 1; }

# 3) 确认 bun 可用（before_install 已装；这里只做校验）
if [ ! -x "$BUN_BIN" ]; then
  echo "ERROR: bun not found at $BUN_BIN"; exit 1;
fi
sudo -u lobechat env PATH="${BUN_HOME}/bin:/usr/bin:/bin" bash -lc 'bun --version || exit 1'
# 确认 node 可用（systemd 会 source nvm，但这里也验证一次）
sudo -u lobechat env HOME=/opt/lobechat NVM_DIR=/opt/lobechat/.nvm \
  bash -lc '. "$NVM_DIR/nvm.sh"; nvm use --lts >/dev/null; node -v'

log "after_install.sh done"
