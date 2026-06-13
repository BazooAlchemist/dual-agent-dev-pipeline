# Dev Pipeline Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repository easier to adopt by aligning agent working rules, audit schemas, quickstart commands, and reference bridge validation.

**Architecture:** Keep the methodology docs as the source of intent, but add concrete repo-level operating rules and machine-checkable contracts. A single validation script will verify schema presence, doc references, shell syntax, plist syntax, and unresolved high-risk placeholders.

**Tech Stack:** Markdown, JSON Schema draft 2020-12, POSIX shell checks via `bash -n`, macOS `plutil`, repository-local validation script.

---

### Task 1: Repository Workflow Guardrails

**Files:**
- Create: `AGENTS.md`
- Modify: `.gitignore`
- Test: `scripts/validate-repo.sh`

- [x] **Step 1: Write repository validation script**

Create `scripts/validate-repo.sh` with checks for `.codegraph/` ignore rules, schema files, schema references, shell syntax, plist syntax, and stale product naming.

- [x] **Step 2: Run validation and observe failure**

Run: `bash scripts/validate-repo.sh`
Expected: FAIL because `schema/audit-request.schema.json`, `schema/audit-response.schema.json`, and updated references do not exist yet.

- [x] **Step 3: Add agent workflow rules**

Create `AGENTS.md` with risk tiering, CodeGraph handling, TDD expectations, verification gates, and dual-agent audit behavior for future repo work.

- [x] **Step 4: Ignore local CodeGraph cache**

Add `.codegraph/` to `.gitignore` so local indexing artifacts stay out of version control.

### Task 2: Single Audit Schema Contract

**Files:**
- Create: `schema/audit-request.schema.json`
- Create: `schema/audit-response.schema.json`
- Modify: `core/04-dual-agent-audit.md`
- Modify: `adapters/codex-auditor.md`
- Modify: `examples/governance-dual-audit.md`
- Modify: `examples/dev-pipeline-skill.md`
- Test: `scripts/validate-repo.sh`

- [x] **Step 1: Add canonical request schema**

Create `schema/audit-request.schema.json` using `type`, `gate`, `version`, `round`, `payload.context`, and `payload.artifacts` as the only canonical request shape.

- [x] **Step 2: Add canonical response schema**

Create `schema/audit-response.schema.json` using `type`, `gate`, `version`, `round`, `result.verdict`, `result.findings`, and `result.summary` as the only canonical response shape.

- [x] **Step 3: Replace divergent docs with canonical references**

Update the core, adapter, governance, and skill example docs so their JSON examples use the same field names.

- [x] **Step 4: Run validation**

Run: `bash scripts/validate-repo.sh`
Expected: PASS for schema presence and divergent schema name checks.

### Task 3: Copyable Onboarding and Bridge Checks

**Files:**
- Modify: `QUICKSTART.md`
- Modify: `deploy/codex-bridge/README.md`
- Modify: `deploy/codex-bridge/setup-codex-bridge.sh`
- Modify: `deploy/codex-bridge/health-check.sh`
- Modify: `README.md`
- Test: `scripts/validate-repo.sh`

- [x] **Step 1: Make Quickstart commands safe**

Use `mkdir -p`, `install -m 0644`, and backup/merge guidance before touching user config files.

- [x] **Step 2: Make bridge setup create required directories**

Ensure the setup script creates `~/Library/LaunchAgents`, bridge directories, and logs directory, and prints exact replacement commands.

- [x] **Step 3: Make health check fail when unhealthy**

Make `health-check.sh` return non-zero when the process or inbox is missing, while still printing actionable status.

- [x] **Step 4: Reposition bridge as reference deployment**

Adjust README wording so the repository does not overpromise a complete bundled worker when the worker is external.

- [x] **Step 5: Run validation**

Run: `bash scripts/validate-repo.sh`
Expected: PASS for shell syntax, plist syntax, stale naming, and schema references.
