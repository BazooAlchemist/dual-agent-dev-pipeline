<!--
  governance-dual-audit.md — Dual-agent cross-audit rules file (example)
  =====================================================================
  What this file is:
  Governance rules for dual-agent cross-audit between your primary coding
  agent (e.g., Claude Code CLI) and an independent external audit agent
  (e.g., Codex on a different model provider). Defines when to trigger
  external audit, what happens when the audit agent is unavailable, and
  the R1-R4 convergence protocol.

  What you need to change:
  1. Replace `<your-audit-agent-name>` with your external audit agent name.
  2. Replace `<your-bridge-deploy-path>` with your bridge deployment path.
  3. Adjust the availability check command (Step 2 below).
  4. Verify the file loads correctly (Step 3 below).
-->

# Dual-Agent Cross-Audit Governance Rules

**Version**: 1.1 (generic)
**Applies to**: Any dual-agent workflow where the coding agent and the
audit agent run on different model providers, to catch blind spots the
execution agent cannot see.

> **Purpose**: The executing agent "does not know it is making mistakes."
> An independent external audit agent (different model provider, different
> context window) catches these blind spots. This file defines when to
> trigger it, what happens when it is unavailable, and how to converge.

---

## 1. Impact Tier Determination

When a change touches files, determine the tier based on **capability
domains** (not filenames). The highest-matching capability domain wins.
Governance rules take priority — any change that weakens existing
security controls is promoted at least one tier.

### High Impact — External audit agent is a hard gate

| Capability Domain | Description |
|-------------------|-------------|
| Agent selection & routing | Changing which model, provider, or agent type handles tasks |
| Bridge protocol | Changing inter-agent communication protocol, message format, task dispatch logic |
| Session / lock mechanism | Changing session lifecycle, concurrency control, lock management |
| Authentication & permissions | Changing token management, permission scope, access control |
| Service lifecycle | Changing daemon start/stop/health-check configuration |
| Audit standard weakening | Removing gates, loosening review standards, lowering impact tiers, bypassing verification steps |

### Medium Impact — External audit preferred; degraded review when unavailable

| Capability Domain | Description |
|-------------------|-------------|
| Business logic processing | Non-auth hooks, handlers, data processing logic |
| Skill / workflow creation | Extending automation without changing existing gates |
| Governance rule additions | Adding rules, supplementary descriptions (non-weakening) |
| Plan execution | Implementing an already-approved plan into code |

### Low Impact — Built-in verification is sufficient; no external audit needed

| Capability Domain | Description |
|-------------------|-------------|
| Format fixes | Indentation, comments, non-semantic adjustments |
| One-shot diagnostic scripts | Temporary troubleshooting scripts |
| Pure documentation | Non-governance `.md` files |

> **File examples for each domain** are provided in `appendix/file-trigger-examples.md`
> (non-normative, for reference only).

### Determination Flow

```
Change touches files → map each file to capability domains →
pick highest-tier domain → check governance rule priority
    (weakening security control → promote one tier) →
final tier = High / Medium / Low
```

---

## 2. Dual Gate Flow

```
Change → Impact tier determination
         │
Gate ① (Architecture audit): After architecture review, before writing code
  ├─ High impact → External audit agent reviews architecture/design
  │                Audit target: architecture review output + implementation plan
  │                Audit agent unavailable → BLOCK (wait for recovery, or break-glass)
  └─ Medium/Low → Skip (architecture review is sufficient)
         │
Implementation + review + SAST + verification
         │
Gate ② (Delivery audit): After all checks pass, before ship
  ├─ High impact → External audit agent: hard gate
  │                Agent available → 0 BLOCKER → release
  │                Agent unavailable → hard BLOCK (or break-glass)
  ├─ Medium impact → External audit preferred
  │                  Agent available → audit → release
  │                  Agent unavailable → degraded review → release + 24h catch-up audit
  └─ Low impact → Built-in verification is sufficient, no extra gate
```

### Availability Check

"External audit agent is available" requires ALL of:

1. Bridge process is running (`<your-bridge-status-command>` returns PID > 0)
2. Current session can successfully send a task and receive a response

If either condition fails, the agent is unavailable. Workflow-internal
agents must NOT self-declare availability.

---

## 3. Degraded Review Mechanism (Medium Impact, Gate 2 only)

When Gate 2 triggers on a Medium-impact change and the external audit
agent is unavailable:

1. Dispatch a review sub-agent via workflow `agent()`, using a **different
   model tier** than the main agent (e.g., main uses model-X, review uses
   model-Y; different providers preferred).
2. Tag the review result: `DEGRADED REVIEW — NOT <your-audit-agent-name> equivalent`.
3. Use the same output schema as the external audit agent (BLOCKER / FIX / NOTE + final verdict).
4. Degraded review passes (0 BLOCKER) → release.
5. Within 24 hours, submit a catch-up audit to the external audit agent.
   The execution agent of THIS task owns the catch-up. Create the catch-up
   task in the execution log with a 24-hour deadline. The handoff or PR
   delivery owner follows up until closed.

### Tags

| Tag | Written Where | Meaning |
|-----|--------------|---------|
| `[degraded-audit]` | Execution log review section + delivery metadata (handoff/PR description) | Degraded review passed; awaiting catch-up audit |
| `[emergency-bypass]` | Same + referenced in catch-up audit task | Emergency hot-fix bypassing audit gate |

---

## 4. Emergency Hot-Fix Break-Glass

When a High-impact change + external audit agent unavailable + immediate
deployment required:

1. User explicitly authorizes bypass (explicit approval or `!force-merge` command).
2. Emergency fixes only (production outage, service interruption, security
   incident). NOT for regular feature development.
3. Auto-tag `[emergency-bypass]`.
4. Minimum runtime verification MUST pass (`verification-before-completion`).
5. Within 24 hours, mandatory catch-up audit by external audit agent.
   The execution agent of THIS task owns the catch-up. Create the catch-up
   task in the execution log with a 24-hour deadline.
6. Catch-up audit finds BLOCKER → must immediately fix or roll back.
   "Already deployed" is NOT an exemption.

---

## 5. Convergence Protocol (R1-R4 Rounds)

| Round | Content | Verdict |
|-------|---------|---------|
| R1 | External audit agent initial review | BLOCKER / FIX / NOTE |
| R2 | Implementer submits fixes; audit agent verifies | Per-item: RESOLVED / PARTIAL / NOT_FIXED |
| R3 | Additional fixes (if PARTIAL / NOT_FIXED remain) | Same as R2 |
| R4 | Final verdict | PASS / BLOCKED |

- **Convergence condition**: 0 BLOCKER, all FIX items resolved.
- **Max 4 rounds**. R4 not converged → escalated to user decision.
- Each round's verdict and execution log MUST be recorded.

---

## 6. Bridge Message JSON Schema

Canonical schema files:

- Request: `schema/audit-request.schema.json`
- Response: `schema/audit-response.schema.json`

Use this request shape to dispatch audit tasks to the external audit agent:

```json
{
  "type": "audit_request",
  "gate": "gate_2",
  "version": "1.0",
  "round": 1,
  "payload": {
    "context": {
      "task": "<description of the change to audit>",
      "risk_level": "medium",
      "impact_domains": ["Skill / workflow creation"],
      "files_changed": ["examples/dev-pipeline-skill.md"]
    },
    "artifacts": {
      "diff": "<current diff>",
      "verification_log": "<verification command output>"
    }
  }
}
```

Expected response schema:

```json
{
  "type": "audit_response",
  "gate": "gate_2",
  "version": "1.0",
  "round": 1,
  "result": {
    "verdict": "PASS",
    "findings": [
      {
        "severity": "NOTE",
        "category": "completeness",
        "location": "examples/dev-pipeline-skill.md",
        "description": "<finding description>",
        "suggestion": "<suggested follow-up>"
      }
    ],
    "summary": "<summary verdict>"
  }
}
```

The audit agent MUST NOT be the same model provider as the main execution
agent. The response must include at least one finding or an explicit
"no issues found" PASS.

---

## 7. External Audit Agent Interface Contract

Any agent serving as the external auditor MUST satisfy:

| Requirement | Detail |
|-------------|--------|
| Different model provider | Must not use the same model provider as the execution agent |
| Structured output | Must conform to `schema/audit-response.schema.json` |
| Round-trip support | Must understand R1-R4 round semantics |
| Convergence awareness | Must respect the 4-round cap and escalation rule |
| Catch-up audit support | Must accept catch-up audit tasks post-deployment (24h window) |

---

## 8. What You Need to Change

1. **Audit agent name**: Replace `<your-audit-agent-name>` throughout this file.
2. **Bridge status command**: Replace `<your-bridge-status-command>` in the
   availability check section with your actual bridge process check.
3. **Bridge deploy path**: If you have a bridge setup, note its path here:
   `<your-bridge-deploy-path>` (e.g., `$HOME/.your-bridge/`).
4. **Tag location**: Update the tag write-locations (execution log path,
   delivery metadata format) to match your workflow.

---

## 9. How to Verify

After placing this file in your workflow rules:

1. Run a test change that touches a High-impact capability domain
   (e.g., modify a bridge protocol). Confirm Gate 1 fires.
2. Verify the external audit agent receives the task and responds.
3. Simulate audit agent unavailability → confirm degraded review or
   break-glass path works.
4. Confirm no residual references to your original environment paths
   (run `grep -rn 'OriginalEnv\|old-path\|your-old-agent'` on the file).
