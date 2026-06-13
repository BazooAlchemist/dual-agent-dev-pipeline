#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_file() {
  local path="$1"
  test -f "$path" || fail "missing required file: $path"
}

require_grep() {
  local pattern="$1"
  local path="$2"
  rg -q "$pattern" "$path" || fail "pattern '$pattern' not found in $path"
}

reject_grep() {
  local pattern="$1"
  local path="$2"
  if rg -q "$pattern" "$path"; then
    fail "unexpected pattern '$pattern' found in $path"
  fi
}

require_file "schema/audit-request.schema.json"
require_file "schema/audit-response.schema.json"
require_file "AGENTS.md"

require_grep '^\.codegraph/$' ".gitignore"

for path in \
  "core/04-dual-agent-audit.md" \
  "adapters/codex-auditor.md" \
  "examples/governance-dual-audit.md" \
  "examples/dev-pipeline-skill.md" \
  "deploy/codex-bridge/README.md"; do
  require_grep 'schema/audit-request.schema.json' "$path"
  require_grep 'schema/audit-response.schema.json' "$path"
done

reject_grep 'Adobe Codex' "adapters/claude-code.md"
reject_grep '"messageType"|"auditGate"|"convergenceRound"|"riskTier"' "adapters/codex-auditor.md"
reject_grep '"audit_type"|"status": "PASS"' "examples/governance-dual-audit.md"
reject_grep '"audit_type": "architecture \| code"' "examples/dev-pipeline-skill.md"

bash -n deploy/codex-bridge/setup-codex-bridge.sh
bash -n deploy/codex-bridge/health-check.sh
plutil -lint deploy/codex-bridge/codex-bridge-launchd.plist >/dev/null

echo "OK: repository validation passed"
