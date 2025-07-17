#!/bin/bash

# AWS App Runner Build Script for Lobe Chat
# This script installs bun and builds the Next.js application

set -e # Exit on any error

echo "🚀 Starting AWS App Runner build process..."

# Install required dependencies for bun (curl should be pre-installed)
echo "📦 Checking for required dependencies..."
which curl || dnf install -y curl

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

# Allow postinstalls for App Runner
echo "🔧 Allowing postinstalls..."
$BUN_INSTALL/bin/bun pm untrusted --all 2>/dev/null || true

# Load App Runner specific environment variables
echo "🔧 Loading App Runner environment variables..."
if [ -f .env.apprunner ]; then
    export $(cat .env.apprunner | grep -v '^#' | xargs)
fi

# Set additional environment variables for App Runner
echo "🔧 Setting environment variables..."
export NODE_ENV=production
export DOCKER=true
export NODE_OPTIONS="--max-old-space-size=4096"
export NEXT_TELEMETRY_DISABLED=1

# Use minimal config for App Runner
echo "🔧 Using minimal Next.js configuration..."
cp next.config.minimal.ts next.config.ts

# Run prebuild script
echo "🔧 Running prebuild script..."
$BUN_INSTALL/bin/bun run prebuild

# Build the application
echo "🏗️ Building the application..."
echo "Node options: $NODE_OPTIONS"

$BUN_INSTALL/bin/bun run build 2>&1 | tee build.log || {
    echo "❌ Build failed. Showing build log:"
    echo "=== Last 50 lines ==="
    tail -50 build.log
    echo "=== Environment ==="
    env | grep -E '(NODE|NEXT)'
    echo "=== Config file ==="
    head -20 next.config.ts
    exit 1
}

# Make the build directory accessible to App Runner
echo "🔧 Setting permissions for build artifacts..."
chmod -R 755 .next

echo "✅ Build completed successfully!"