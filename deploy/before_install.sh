#!/usr/bin/env bash
set -euo pipefail

# 1) 基础依赖
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y awscli jq curl unzip

# 2) 创建运行用户与目录
id -u lobechat >/dev/null 2>&1 || useradd --system --home /opt/lobechat --shell /usr/sbin/nologin lobechat
mkdir -p /opt/lobechat
chown -R lobechat:lobechat /opt/lobechat

# 3) 安装 Bun（给 lobechat 用户）
if [ ! -x /home/lobechat/.bun/bin/bun ]; then
  su -s /bin/bash - lobechat -c 'curl -fsSL https://bun.sh/install | bash'
fi

# 4) 写入 systemd 单元（如不存在或需更新）
cat >/etc/systemd/system/lobechat.service <<'UNIT'
[Unit]
Description=LobeChat (Bun) Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/lobechat
EnvironmentFile=/opt/lobechat/.env
User=lobechat
ExecStart=/bin/bash -lc 'export BUN_INSTALL=/home/lobechat/.bun; export PATH=/home/lobechat/.bun/bin:$PATH; bun run start'
Restart=always
RestartSec=5
# 可选：限制内存/文件句柄等
# LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
# 停老进程（如果有）
systemctl stop lobechat || true
