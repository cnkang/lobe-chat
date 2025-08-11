#!/usr/bin/env bash
set -euo pipefail
systemctl enable lobechat.service
systemctl restart lobechat.service
systemctl status lobechat.service --no-pager || true
