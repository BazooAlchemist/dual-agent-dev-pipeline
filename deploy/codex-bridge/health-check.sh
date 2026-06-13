#!/bin/bash
# health-check.sh — Reference health check for Codex bridge
# [reference] Tested on 1 environment.

set -euo pipefail

STATUS=0

echo "==> Codex Bridge Health Check"

# Check process
if launchctl list | grep -q "codex-bridge"; then
  echo "✔ codex-bridge process: RUNNING"
else
  echo "✘ codex-bridge process: NOT FOUND"
  STATUS=1
fi

# Check inbox
INBOX_DIR="${HOME}/.openclaw/bridges/codex/inbox"
if [ -d "$INBOX_DIR" ]; then
  INBOX_COUNT=$(ls "$INBOX_DIR" 2>/dev/null | wc -l | tr -d ' ')
  echo "✔ Inbox: $INBOX_COUNT pending tasks"
else
  echo "✘ Inbox directory not found"
  STATUS=1
fi

# Check recent activity
DONE_DIR="${HOME}/.openclaw/bridges/codex/done"
if [ -d "$DONE_DIR" ]; then
  RECENT=$(ls -t "$DONE_DIR" 2>/dev/null | head -1)
  echo "✔ Latest completed: ${RECENT:-none}"
fi

exit "$STATUS"
