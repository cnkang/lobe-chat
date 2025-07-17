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
$BUN_INSTALL/bin/bun install --frozen-lockfile

# Run prebuild script
echo "🔧 Running prebuild script..."
$BUN_INSTALL/bin/bun run prebuild

# Build the application
echo "🏗️ Building the application..."
$BUN_INSTALL/bin/bun run build

# Make the build directory accessible to App Runner
echo "🔧 Setting permissions for build artifacts..."
chmod -R 755 .next

echo "✅ Build completed successfully!"
