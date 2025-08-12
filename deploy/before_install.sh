#!/usr/bin/env bash
set -euo pipefail
log(){ echo "[$(date +'%F %T')] $*"; }

export DEBIAN_FRONTEND=noninteractive

APP_DIR="/opt/lobechat"
BUN_HOME="${APP_DIR}/.bun"
NVM_DIR="${APP_DIR}/.nvm"

log "==> Install base packages (jq curl unzip ruby ca-certificates)"
apt-get update -y
apt-get install -y --no-install-recommends jq curl unzip ruby ca-certificates

log "==> Ensure service user/group and app dir"
getent group lobechat >/dev/null || groupadd --system lobechat
id -u lobechat >/dev/null 2>&1 || useradd --system --gid lobechat --home "$APP_DIR" --shell /usr/sbin/nologin lobechat
mkdir -p "$APP_DIR"
chown -R lobechat:lobechat "$APP_DIR"
chmod 755 "$APP_DIR"

log "==> Ensure Bun for lobechat (optional runtime tool)"
if [ ! -x "${BUN_HOME}/bin/bun" ]; then
  sudo -u lobechat env HOME="$APP_DIR" BUN_INSTALL="$BUN_HOME" bash -lc 'curl -fsSL https://bun.sh/install | bash'
fi
sudo -u lobechat env PATH="${BUN_HOME}/bin:/usr/bin:/bin" bash -lc 'bun --version || true'

log "==> Ensure NVM present"
if [ ! -s "${NVM_DIR}/nvm.sh" ]; then
  sudo -u lobechat env HOME="$APP_DIR" bash -lc 'mkdir -p "$HOME/.nvm"; curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
fi

log "==> Ensure Node LTS via NVM (install+use)"
sudo -u lobechat env HOME="$APP_DIR" NVM_DIR="$NVM_DIR" bash -lc '
  set -e
  . "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default lts/*
  nvm use --lts
  which node; node -v
'

log "==> Write systemd unit (Node via NVM, AF_PACKET/AF_NETLINK allowed)"
cat >/etc/systemd/system/lobechat.service <<'UNIT'
[Unit]
Description=LobeChat (Node via NVM)
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

ExecStart=/bin/bash -lc 'set -e; \
  export NVM_DIR=/opt/lobechat/.nvm; \
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; \
  nvm install --lts >/dev/null 2>&1 || true; \
  nvm use --lts >/dev/null; \
  export PATH="$(dirname "$(nvm which --lts)"):$PATH"; \
  cd /opt/lobechat; \
  echo "Node=$(command -v node) $(node -v)"; \
  exec node node_modules/next/dist/bin/next start -p 3210'

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
# 放行获取网卡信息所需的地址族
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_PACKET AF_NETLINK
ReadWritePaths=/opt/lobechat
CapabilityBoundingSet=
AmbientCapabilities=

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl stop lobechat || true

# 统一归属（防止复制出的文件是 root:root）
chown -R lobechat:lobechat "$APP_DIR"
log "before_install.sh done"
