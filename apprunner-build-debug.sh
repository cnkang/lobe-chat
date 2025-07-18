#!/bin/bash

# AWS App Runner Debug Build Script for Lobe Chat
# This script provides more detailed debugging information

set -e # Exit on any error

echo "🚀 Starting AWS App Runner debug build process..."

# Show system information
echo "📊 System Information:"
echo "Memory: $(free -h 2>/dev/null || echo 'N/A')"
echo "CPU: $(nproc 2>/dev/null || echo 'N/A')"
echo "Node version: $(node --version 2>/dev/null || echo 'N/A')"
echo "NPM version: $(npm --version 2>/dev/null || echo 'N/A')"

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

# Load App Runner specific environment variables
echo "🔧 Loading App Runner environment variables..."
if [ -f .env.apprunner ]; then
    export $(cat .env.apprunner | grep -v '^#' | xargs)
fi

# Set additional environment variables for App Runner
echo "🔧 Setting environment variables..."
export NODE_ENV=production
export DOCKER=true
export NODE_OPTIONS="--max-old-space-size=8192"
export NEXT_TELEMETRY_DISABLED=1

echo "Environment variables:"
echo "NODE_ENV: $NODE_ENV"
echo "DOCKER: $DOCKER"
echo "NODE_OPTIONS: $NODE_OPTIONS"
echo "NEXT_TELEMETRY_DISABLED: $NEXT_TELEMETRY_DISABLED"

# Install dependencies with more verbose output
echo "📦 Installing dependencies with bun..."
$BUN_INSTALL/bin/bun install --verbose 2>&1 | tee install.log

# Check if installation was successful
if [ $? -ne 0 ]; then
    echo "❌ Dependency installation failed. Showing install log:"
    cat install.log
    exit 1
fi

# Run prebuild script
echo "🔧 Running prebuild script..."
$BUN_INSTALL/bin/bun run prebuild 2>&1 | tee prebuild.log || {
    echo "❌ Prebuild failed. Showing prebuild log:"
    cat prebuild.log
    exit 1
}

# Try a simple Next.js build first
echo "🏗️ Attempting simple Next.js build..."
echo "Using Next.js config: next.config.apprunner.ts"
echo "Node options: $NODE_OPTIONS"

# Copy the App Runner config as the main config
cp next.config.apprunner.ts next.config.ts

# Try building with maximum verbosity
$BUN_INSTALL/bin/bun run build --verbose 2>&1 | tee build.log || {
    echo "❌ Build failed. Showing detailed build log:"
    echo "=== Last 100 lines of build log ==="
    tail -100 build.log
    echo "=== Full build log ==="
    cat build.log
    echo "=== Package.json build script ==="
    grep -A 5 -B 5 '"build"' package.json
    echo "=== Next.js config ==="
    head -50 next.config.ts
    exit 1
}

# Make the build directory accessible to App Runner
echo "🔧 Setting permissions for build artifacts..."
chmod -R 755 .next

echo "✅ Build completed successfully!"