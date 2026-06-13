# QUICKSTART — Dual-Agent Dev Pipeline

> **~30 min target** (best-case path; actual time varies by environment and prior setup).

---

## What This Is

The Dual-Agent Dev Pipeline is a methodology and reference deployment guide for
structured AI-assisted development on macOS: 12 pipeline steps, 3-layer
architecture, and a dual-agent audit protocol that catches what a single AI
can't see itself doing wrong.

## Who This Is For

Developers on macOS using **Claude Code CLI** who want a repeatable process
for writing, reviewing, and shipping code with AI, and who optionally deploy
a **Codex (or other external-audit agent)** for cross-model verification.

## What This Quickstart Does NOT Cover

- Non-macOS environments
- Deploying an external audit agent (see `deploy/codex-bridge/README.md`)
- Every edge case in pipeline configuration

---

## Step 1 — Clone the repo and understand the structure (2 min)

```bash
git clone <your-repo-url> dual-agent-dev-pipeline
cd dual-agent-dev-pipeline
```

Browse the layout:

| Directory | Purpose |
|-----------|---------|
| `core/` | 5 methodology docs (pipeline steps, risk tiers, audit, architecture) |
| `adapters/` | 3 tool-mapping guides (Claude Code, Codex auditor) |
| `examples/` | 4 configuration templates (skill, rules, CLAUDE.md, settings.json) |
| `deploy/codex-bridge/` | 4 reference artifacts for Codex bridge deployment |
| `appendix/` | 2 non-normative reference docs (file triggers, real-world cases) |
| `PHILOSOPHY.md` | Design rationale |
| `QUICKSTART.md` | (this file) |

**Done with Step 1 when:** you can name what each directory holds.

---

## Step 2 — Deploy the dev-pipeline skill (5 min)

Copy the example skill file into Claude Code's skill directory:

```bash
mkdir -p ~/.claude/skills/dev-pipeline
install -m 0644 examples/dev-pipeline-skill.md ~/.claude/skills/dev-pipeline/SKILL.md
```

Then verify the skill is loadable:

```bash
claude skills list | grep dev-pipeline
```

If the file is present but the skill doesn't appear, restart Claude Code.

**Done with Step 2 when:** `claude skills list` shows a `dev-pipeline` entry.

> **If you already customized this skill:** copy to a temporary path first, diff it against your existing file, and merge the pipeline sections manually.

---

## Step 3 — Deploy the dual-agent audit rules (5 min)

Copy the example governance rules into your project memory or a location your
external audit agent can reference:

```bash
mkdir -p ~/.claude/projects/<your-project>/memory
install -m 0644 examples/governance-dual-audit.md ~/.claude/projects/<your-project>/memory/governance-dual-audit.md
```

Or place it wherever your audit agent reads its rules (e.g., workspace shared
with Codex).

**Done with Step 3 when:** the audit rules file is accessible from both Claude
Code and your external audit agent.

> **What to edit:** Open the file and replace `<your-audit-agent-name>` and any
> placeholder paths with your actual setup.

---

## Step 4 — Configure CLAUDE.md (10 min)

Reference the example CLAUDE.md skeleton to build or update your own:

```bash
mkdir -p ~/.claude
if [ -f ~/.claude/CLAUDE.md ]; then
  cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.before-dev-pipeline
  install -m 0644 examples/CLAUDE.md.example ~/.claude/CLAUDE.md.dev-pipeline.example
  echo "Existing CLAUDE.md preserved. Merge ~/.claude/CLAUDE.md.dev-pipeline.example into ~/.claude/CLAUDE.md."
else
  install -m 0644 examples/CLAUDE.md.example ~/.claude/CLAUDE.md
fi
# ... then edit the target file to replace all <your-*> placeholders
```

The skeleton includes:

- Execution mode declaration (Dynamic Workflows)
- Key path quick-reference (fill in your install paths)
- Skill binding rules table (add your project's skill names)
- Dev pipeline quick-reference table (12 steps)
- Dual-agent audit trigger rules (capability-based)

**Done with Step 4 when:** `claude` starts without errors and your pipeline
rules appear in the system prompt on the first turn of a new session.

> **If you already have a CLAUDE.md:** merge the pipeline sections selectively
> rather than overwriting.

---

## Step 5 — Verify the pipeline is active (8 min)

Start a Claude Code session and submit a test task — for example, a small
script or config change. Watch for:

1. The system prompt includes pipeline instructions (risk tiering, 12-step
   flow, audit triggers).
2. Claude references pipeline phases in its plan ("Phase 0: exploration",
   "risk tier: low/mid/high").
3. If you have an external audit agent deployed, it receives the audit
   message and responds.

To be thorough, run the verification command from the plan:

```bash
FILE=~/.claude/skills/dev-pipeline/SKILL.md
test -f "$FILE" && echo "Skill OK" || echo "Skill MISSING"
grep "dev-pipeline" ~/.claude/skills/dev-pipeline/SKILL.md >/dev/null 2>&1 && echo "Content OK"
bash scripts/validate-repo.sh
```

**Done with Step 5 when:** Claude initiates at least a basic risk assessment
and pipeline structure in response to a new task.

---

## Next Steps

- **Deploy Codex bridge** for full dual-agent audit → `deploy/codex-bridge/README.md`
- **Understand the methodology** → `core/01-pipeline-overview.md`
- **Design philosophy** → `PHILOSOPHY.md`
- **Risk tiers and when to skip steps** → `core/03-risk-tiers.md`
