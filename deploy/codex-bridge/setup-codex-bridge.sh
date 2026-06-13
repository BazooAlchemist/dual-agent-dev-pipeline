#!/bin/bash
# setup-codex-bridge.sh — Reference script for deploying Codex bridge on macOS
# [reference] Tested on 1 environment. Not guaranteed for all macOS setups.
# Prerequisites: Node.js >= 18, Claude Code CLI, Codex CLI

set -euo pipefail

HOME_DIR="${HOME}"
AGENTFOUNDRY_ROOT="${AGENTFOUNDRY_ROOT:-$HOME_DIR/AI/AgentFoundry}"
BRIDGE_DIR="$HOME_DIR/.openclaw/bridges/codex"
LOG_DIR="$HOME_DIR/.openclaw/logs"
PLIST_TARGET="$HOME_DIR/Library/LaunchAgents/ai.openclaw.codex-bridge.plist"

echo "==> Creating bridge directories..."
mkdir -p "$BRIDGE_DIR"/{inbox,processing,done,failed,archive}
mkdir -p "$LOG_DIR"
mkdir -p "$HOME_DIR/Library/LaunchAgents"

echo "==> Copy launchd plist..."
install -m 0644 "$(dirname "$0")/codex-bridge-launchd.plist" "$PLIST_TARGET"

echo "==> Edit $PLIST_TARGET before loading:"
echo "    perl -pi -e 's#<your-home>#$HOME_DIR#g; s#<your-agentfoundry-root>#$AGENTFOUNDRY_ROOT#g; s#/path/to/node#$(command -v node || echo /path/to/node)#g' \"$PLIST_TARGET\""
echo "==> Then: launchctl bootstrap gui/\$(id -u) \"$PLIST_TARGET\""
echo "==> Verify: launchctl list | grep codex-bridge"
