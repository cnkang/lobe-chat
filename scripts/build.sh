#!/usr/bin/env bash
set -euo pipefail

echo "=== LobeChat build start ==="

# 0) 兜底并行与内存（若外部未传入）
: "${THREADS:=$(nproc)}"
: "${TOTAL_MB:=$(awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo)}"
: "${HEAP_MB:=$(( TOTAL_MB * 80 / 100 ))}"
if [ "$HEAP_MB" -lt 6144 ]; then HEAP_MB=6144; fi

export NODE_ENV="${NODE_ENV:-production}"
export NEXT_TELEMETRY_DISABLED="${NEXT_TELEMETRY_DISABLED:-1}"

# Node/Bun/SWC 参数
export NODE_OPTIONS="--max-old-space-size=${HEAP_MB} --max-semi-space-size=256"
export UV_THREADPOOL_SIZE="${THREADS}"
export BUN_JOBS="${THREADS}"
export SWC_THREADS="${THREADS}"

echo "Node: $(node -v)"
command -v bun >/dev/null 2>&1 && echo "Bun:  $(bun --version)" || echo "Bun:  (not found)"
echo "THREADS=${THREADS}  TOTAL_MB=${TOTAL_MB}  HEAP_MB=${HEAP_MB}"
echo "PWD=$(pwd)"

# 小工具：判断 package.json 是否定义了某个 script（无需 jq）
has_script () {
  # npm v10 支持 pkg get；null 表示不存在
  test "$(npm pkg get "scripts.$1" 2>/dev/null | tr -d '\"')" != "null"
}

# 1) prebuild（如果存在）
if has_script prebuild; then
  echo ">> run prebuild"
  bun run prebuild
else
  echo ">> skip prebuild (no scripts.prebuild)"
fi

# 2) Next.js 构建（使用项目内 next；不从网上装）
echo ">> next build (standalone expected)"
npx --no-install next build

# 3) postbuild（如果存在）
if has_script postbuild; then
  echo ">> run postbuild"
  bun run postbuild
else
  echo ">> skip postbuild (no scripts.postbuild)"
fi

# 4) 强校验：必须产生 standalone 产物
if [ ! -f ".next/standalone/server.js" ]; then
  echo "ERROR: .next/standalone/server.js not found." >&2
  echo "请确认 next.config.js 含有：  module.exports = { output: 'standalone' }" >&2
  [ -f next.config.js ] && { echo '--- next.config.js ---'; sed -n '1,120p' next.config.js; echo '------------------------'; }
  exit 1
fi

echo ">> build outputs (top levels)"
ls -al .next | sed -n '1,80p'
echo ">> .next/standalone sample"
ls -al .next/standalone | sed -n '1,80p' || true
echo ">> .next/static sample"
ls -al .next/static | sed -n '1,80p' || true

echo "=== LobeChat build done ==="
