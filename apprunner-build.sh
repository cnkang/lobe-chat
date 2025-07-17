#!/bin/bash

# AWS App Runner Build Script for Lobe Chat
# This script installs bun and builds the Next.js application

set -e # Exit on any error

echo "🚀 Starting AWS App Runner build process..."

# Install bun
echo "📦 Installing bun..."
curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Verify bun installation
echo "✅ Verifying bun installation..."
$BUN_INSTALL/bin/bun --version

# Install dependencies
echo "📦 Installing dependencies with bun..."
$BUN_INSTALL/bin/bun install

# Trust dependencies for App Runner
echo "🔧 Trusting dependencies..."
$BUN_INSTALL/bin/bun pm trust --all 2>/dev/null || true

# Load App Runner specific environment variables
echo "🔧 Loading App Runner environment variables..."
if [ -f .env.apprunner ]; then
    set -a
    source .env.apprunner 2>/dev/null || true
    set +a
fi

# Set additional environment variables for App Runner
echo "🔧 Setting environment variables..."
export NODE_ENV=production
export DOCKER=true
export NODE_OPTIONS="--max-old-space-size=4096 --max-semi-space-size=128"
export NEXT_TELEMETRY_DISABLED=1
export NEXT_PUBLIC_ANALYTICS_VERCEL=false
export NEXT_PUBLIC_ANALYTICS_POSTHOG=false
export REACT_SCAN_MONITOR_API_KEY=

# Use App Runner specific config
echo "🔧 Using App Runner Next.js configuration..."
cp next.config.apprunner.ts next.config.ts

# Run prebuild script
echo "🔧 Running prebuild script..."
$BUN_INSTALL/bin/bun run prebuild

# Build the application
echo "🏗️ Building the application..."
echo "Node options: $NODE_OPTIONS"

# Debug information before build
echo "=== Pre-build Debug Info ==="
echo "Current directory: $(pwd)"
echo "Node version: $(node --version)"
echo "Bun version: $($BUN_INSTALL/bin/bun --version)"
echo "Available memory: $(free -h 2>/dev/null || echo 'N/A')"
echo "Next.js config file:"
ls -la next.config.ts
echo "Environment variables:"
env | grep -E '(NODE|NEXT|DOCKER)' | sort

# Run build and capture both stdout and stderr
echo "Starting Next.js build..."
if $BUN_INSTALL/bin/bun run build:apprunner 2>&1 | tee build.log; then
    echo "✅ Build completed successfully!"
else
    BUILD_EXIT_CODE=$?
    echo "❌ Build failed with exit code: $BUILD_EXIT_CODE"
    echo "=== Build Log (Last 200 lines) ==="
    tail -200 build.log
    echo "=== Disk Space ==="
    df -h
    echo "=== Memory Usage ==="
    free -h 2>/dev/null || echo 'Memory info not available'
    echo "=== Next.js Config ==="
    cat next.config.ts
    exit $BUILD_EXIT_CODE
fi

# Verify build output exists
if [ ! -d ".next" ]; then
    echo "❌ .next directory not found after build"
    exit 1
fi

# Make the build directory accessible to App Runner
echo "🔧 Setting permissions for build artifacts..."
chmod -R 755 .next