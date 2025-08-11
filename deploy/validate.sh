#!/usr/bin/env bash
set -euo pipefail
# 根据你的实际监听端口/健康检查路径调整
curl -fsS -m 10 -o /dev/null http://127.0.0.1:3210/ || exit 1
