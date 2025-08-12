#!/usr/bin/env bash
set -euo pipefail
log(){ echo "[$(date +'%F %T')] $*"; }

APP_DIR="/opt/lobechat"
REGION="us-east-1"
SSM_PREFIX="/newswarrior/lobechat"
BUN_HOME="${APP_DIR}/.bun"
BUN_BIN="${BUN_HOME}/bin/bun"

cd "$APP_DIR"

# 1) 拉取 SSM 参数 -> .env（覆盖）
: > .env
echo "NODE_ENV=production" >> .env

NEXT_TOKEN=""
while :; do
  if [ -z "${NEXT_TOKEN}" ]; then
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

# 2) 确保 bun 存在（安装在 /opt/lobechat/.bun）
if [ ! -x "$BUN_BIN" ]; then
  log "bun not found, installing Bun for user lobechat..."
  sudo -u lobechat env HOME="$APP_DIR" BUN_INSTALL="$BUN_HOME" \
    bash -lc 'curl -fsSL https://bun.sh/install | bash'
fi

# 3) 验证 bun 可用（在 lobechat 用户下，附带 PATH）
sudo -u lobechat env PATH="${BUN_HOME}/bin:/usr/bin:/bin" \
  bash -lc 'bun --version'

# 4) （可选）安装依赖
# 如果你在 build 阶段已经把 node_modules 打进 artifact，可以跳过这一步。
# 下方逻辑：当 node_modules 缺失或 bun.lockb 不存在时，才执行安装。
if [ ! -d node_modules ] || [ ! -f bun.lockb ]; then
  log "Installing production dependencies with Bun..."
  sudo -u lobechat env PATH="${BUN_HOME}/bin:/usr/bin:/bin" \
    bash -lc 'bun install --no-progress'
else
  log "Skip bun install (node_modules / bun.lockb already present)"
fi

log "after_install.sh done"
