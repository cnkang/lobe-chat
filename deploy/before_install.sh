#!/usr/bin/env bash
set -euo pipefail
log(){ echo "[$(date +'%F %T')] $*"; }

export DEBIAN_FRONTEND=noninteractive

# ---------- 0) 小工具函数 ----------
need_cmd(){ command -v "$1" >/dev/null 2>&1 || return 0 && return 1; }
ensure_pkg(){
  local pkgs=("$@")
  apt-get update -y
  apt-get install -y --no-install-recommends "${pkgs[@]}"
}

# ---------- 1) 基础依赖（按需装） ----------
MISSING_PKGS=()
need_cmd jq    && MISSING_PKGS+=("jq")
need_cmd curl  && MISSING_PKGS+=("curl")
need_cmd unzip && MISSING_PKGS+=("unzip")
need_cmd ruby  && MISSING_PKGS+=("ruby")

if [ "${#MISSING_PKGS[@]}" -gt 0 ]; then
  log "Installing base packages: ${MISSING_PKGS[*]}"
  ensure_pkg "${MISSING_PKGS[@]}"
else
  log "Base packages already present"
fi

# ---------- 2) AWS CLI v2：存在就跳过；v1 或未安装则安装 ----------
AWS_NEED_INSTALL=0
if ! command -v aws >/dev/null 2>&1; then
  AWS_NEED_INSTALL=1
else
  # 解析主版本号
  AWS_MAJOR="$(aws --version 2>&1 | awk -F/ '{print $2}' | cut -d. -f1)"
  if [ -z "$AWS_MAJOR" ] || [ "$AWS_MAJOR" -lt 2 ]; then
    AWS_NEED_INSTALL=1
  fi
fi

if [ "$AWS_NEED_INSTALL" -eq 1 ]; then
  ARCH="$(uname -m)"
  case "$ARCH" in
    aarch64|arm64) AWS_ZIP="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" ;;
    x86_64)        AWS_ZIP="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" ;;
    *) log "Unknown arch: $ARCH"; exit 1 ;;
  esac
  log "Installing AWS CLI v2 for $ARCH"
  curl -fsSL -o /tmp/awscliv2.zip "$AWS_ZIP"
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install --update
  aws --version || { log "AWS CLI install failed"; exit 1; }
else
  log "AWS CLI already OK: $(aws --version 2>&1)"
fi

# ---------- 3) 运行用户与目录 ----------
if ! getent group lobechat >/dev/null; then
  log "Creating group lobechat"
  groupadd --system lobechat
fi
if ! id -u lobechat >/dev/null 2>&1; then
  log "Creating user lobechat (home=/opt/lobechat, nologin)"
  useradd --system --gid lobechat --home /opt/lobechat --shell /usr/sbin/nologin lobechat
fi
mkdir -p /opt/lobechat
chown -R lobechat:lobechat /opt/lobechat
chmod 755 /opt/lobechat

# ---------- 4) Bun 按需安装（HOME=/opt/lobechat） ----------
if [ ! -x /opt/lobechat/.bun/bin/bun ]; then
  log "Installing Bun for user lobechat"
  sudo -u lobechat env HOME=/opt/lobechat BUN_INSTALL=/opt/lobechat/.bun \
    bash -lc 'curl -fsSL https://bun.sh/install | bash'
fi
sudo -u lobechat env PATH=/opt/lobechat/.bun/bin:/usr/bin:/bin \
  bash -lc 'bun --version || exit 1'

# ---------- 5) systemd 单元（幂等写入） ----------
log "Writing systemd unit /etc/systemd/system/lobechat.service"
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
Environment=PATH=/opt/lobechat/.bun/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/bin/bash -lc 'bun run start'
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

# ---------- 6) 首次占位 .env（AfterInstall 会从 SSM 覆盖） ----------
if [ ! -f /opt/lobechat/.env ]; then
  install -o lobechat -g lobechat -m 600 /dev/null /opt/lobechat/.env
fi

log "before_install.sh done"
