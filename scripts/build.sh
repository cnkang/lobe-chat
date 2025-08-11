#!/bin/bash

# 使用已设置的环境变量
echo "Building with ${THREADS} threads and heap ${HEAP_MB} MB..."

# 设置 Node.js 选项
export NODE_OPTIONS="--max-old-space-size=${HEAP_MB} --max-semi-space-size=256"

# 设置多线程相关环境变量
export UV_THREADPOOL_SIZE=${THREADS}
export BUN_JOBS=${THREADS}
export SWC_THREADS=${THREADS}

# 运行 prebuild
bun run prebuild

# 直接运行 next build
npx next build

# 运行 postbuild
bun run postbuild