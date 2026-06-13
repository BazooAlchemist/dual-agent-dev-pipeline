#!/bin/bash
# setup-codex-bridge.sh — Reference script for deploying Codex bridge on macOS
# [reference] Tested on 1 environment. Not guaranteed for all macOS setups.
# Prerequisites: Node.js >= 18, Claude Code CLI, Codex CLI

set -euo pipefail

HOME_DIR="${HOME}"
AGENTFOUNDRY_ROOT="${AGENTFOUNDRY_ROOT:-$HOME_DIR/AI/AgentFoundry}"
BRIDGE_DIR="$HOME_DIR/.openclaw/bridges/codex"

echo "==> Creating bridge directories..."
mkdir -p "$BRIDGE_DIR"/{inbox,processing,done,failed,archive}

echo "==> Copy launchd plist..."
cp "$(dirname "$0")/codex-bridge-launchd.plist" "$HOME_DIR/Library/LaunchAgents/ai.openclaw.codex-bridge.plist"

echo "==> Edit the plist to replace <your-home> and <your-agentfoundry-root> before loading."
echo "==> Then: launchctl bootstrap gui/\$(id -u) ~/Library/LaunchAgents/ai.openclaw.codex-bridge.plist"
echo "==> Verify: launchctl list | grep codex-bridge"
