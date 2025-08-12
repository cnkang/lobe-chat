#!/usr/bin/env bash
set -euo pipefail
log(){ echo "[$(date +'%F %T')] $*"; }

export DEBIAN_FRONTEND=noninteractive

# 1) 基础依赖（按需）
apt-get update -y
apt-get install -y --no-install-recommends jq curl unzip ruby ca-certificates

# 2) 运行用户与目录
getent group lobechat >/dev/null || groupadd --system lobechat
id -u lobechat >/dev/null 2>&1 || useradd --system --gid lobechat --home /opt/lobechat --shell /usr/sbin/nologin lobechat
mkdir -p /opt/lobechat
chown -R lobechat:lobechat /opt/lobechat
chmod 755 /opt/lobechat

APP_DIR="/opt/lobechat"
BUN_HOME="${APP_DIR}/.bun"
NVM_DIR="${APP_DIR}/.nvm"

# 3) Bun（按需）
if [ ! -x "${BUN_HOME}/bin/bun" ]; then
  log "Installing Bun for user lobechat"
  sudo -u lobechat env HOME="${APP_DIR}" BUN_INSTALL="${BUN_HOME}" \
    bash -lc 'curl -fsSL https://bun.sh/install | bash'
fi
sudo -u lobechat env PATH="${BUN_HOME}/bin:/usr/bin:/bin" bash -lc 'bun --version'

# 4) 写 systemd 单元（含 NVM 环境，注意无行尾注释）
cat >/etc/systemd/system/lobechat.service <<'UNIT'
[Unit]
Description=LobeChat (Bun) Service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=lobechat
Group=lobechat
WorkingDirectory=/opt/lobechat

EnvironmentFile=-/opt/lobechat/.env
Environment=BUN_INSTALL=/opt/lobechat/.bun
Environment=NVM_DIR=/opt/lobechat/.nvm
# 先把 bun 放到 PATH，node 由 ExecStart 内 source nvm.sh 后注入
Environment=PATH=/opt/lobechat/.bun/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 在非交互 systemd 环境下，显式 source nvm.sh 再启动
ExecStart=/bin/bash -lc 'set -e; if [ -s "$NVM_DIR/nvm.sh" ]; then . "$NVM_DIR/nvm.sh"; nvm use --lts >/dev/null; fi; echo "Node=$(command -v node) $(node -v 2>/dev/null || true)"; bun run start'

Restart=always
RestartSec=5
TimeoutStartSec=60
TimeoutStopSec=20

LimitNOFILE=65535
UMask=0027

NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectSystem=full
ProtectHome=true
ProtectControlGroups=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectClock=true
LockPersonality=true
RemoveIPC=true
RestrictSUIDSGID=true
RestrictRealtime=true
RestrictNamespaces=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6

ReadWritePaths=/opt/lobechat
CapabilityBoundingSet=
AmbientCapabilities=

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl stop lobechat || true

# 5) 占位 .env（AfterInstall 会覆盖）
[ -f /opt/lobechat/.env ] || install -o lobechat -g lobechat -m 600 /dev/null /opt/lobechat/.env

# 6) NVM + Node LTS（仅在 lobechat 用户下安装，按需）
if ! sudo -u lobechat env HOME="${APP_DIR}" bash -lc 'command -v node >/dev/null 2>&1'; then
  log "Installing NVM + Node LTS for user lobechat"
  sudo -u lobechat env HOME="${APP_DIR}" \
    bash -lc 'mkdir -p "$HOME/.nvm"; curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
  # 初始化 nvm 并安装 LTS
  sudo -u lobechat env HOME="${APP_DIR}" NVM_DIR="${NVM_DIR}" \
    bash -lc '. "$NVM_DIR/nvm.sh"; nvm install --lts; nvm alias default lts/*; nvm use --lts; node -v; which node'
else
  log "Node already present for lobechat: $(sudo -u lobechat env HOME="${APP_DIR}" bash -lc "node -v")"
fi

log "before_install.sh done"
