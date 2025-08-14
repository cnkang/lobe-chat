#!/usr/bin/env bash
set -euo pipefail
log(){ echo "[$(date +'%F %T')] $*"; }

export DEBIAN_FRONTEND=noninteractive

APP_DIR="/opt/lobechat"
NVM_DIR="${APP_DIR}/.nvm"

log "==> Base packages"
apt-get update -y
apt-get install -y --no-install-recommends jq curl unzip ca-certificates

log "==> Ensure user/group & dir"
getent group lobechat >/dev/null || groupadd --system lobechat
id -u lobechat >/dev/null 2>&1 || useradd --system --gid lobechat --home "$APP_DIR" --shell /usr/sbin/nologin lobechat
mkdir -p "$APP_DIR"
chown -R lobechat:lobechat "$APP_DIR"
chmod 755 "$APP_DIR"

log "==> Install NVM if missing"
if [ ! -s "${NVM_DIR}/nvm.sh" ]; then
  sudo -u lobechat env HOME="$APP_DIR" bash -lc 'mkdir -p "$HOME/.nvm"; curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
fi

log "==> Ensure Node LTS via NVM"
sudo -u lobechat env HOME="$APP_DIR" NVM_DIR="$NVM_DIR" bash -lc '
  set -e
  . "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default lts/*
  nvm use --lts
  which node; node -v
'
echo "export OUTPUT_FILE_TRACING_ROOT=${CODEBUILD_SRC_DIR:-/opt/lobechat}" >/etc/profile.d/lobechat.sh
chmod +x /etc/profile.d/lobechat.sh


log "==> Write systemd unit (Standalone server.js)"
cat >/etc/systemd/system/lobechat.service <<'UNIT'
[Unit]
Description=LobeChat (Node via NVM, standalone)
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=lobechat
Group=lobechat
WorkingDirectory=/opt/lobechat

EnvironmentFile=-/opt/lobechat/.env
Environment=NVM_DIR=/opt/lobechat/.nvm
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 关键：nvm 安装/切换 LTS -> 补 PATH -> 启动 standalone server.js
ExecStart=/bin/bash -lc 'set -e; \
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; \
  nvm install --lts >/dev/null 2>&1 || true; \
  nvm use --lts >/dev/null; \
  export PATH="$(dirname "$(nvm which --lts)"):$PATH"; \
  cd /opt/lobechat/.next/standalone; \
  echo "Node=$(command -v node) $(node -v)"; \
  export PORT=3000; \
  exec node server.js'

Restart=always
RestartSec=5
TimeoutStartSec=60
TimeoutStopSec=20
LimitNOFILE=65535
UMask=0027

# 沙箱：放开网卡信息所需地址族
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
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_PACKET AF_NETLINK
ReadWritePaths=/opt/lobechat
CapabilityBoundingSet=
AmbientCapabilities=

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl stop lobechat || true

# 统一归属（防止 root:root）
chown -R lobechat:lobechat "$APP_DIR"

log "before_install.sh done"
