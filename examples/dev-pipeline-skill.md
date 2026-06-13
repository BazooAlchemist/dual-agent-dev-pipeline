<!--
  ================================================================
  dev-pipeline SKILL.md — 示例文件

  用途：这是 AI 辅助开发流水线 skill 文件。复制到你的
        ~/.claude/skills/dev-pipeline/SKILL.md 后即可使用。

  你需要改哪里：
    1. 第 7 行: 更新描述中的组织名/项目名
    2. 第 41-43 行: 修改为你的 CLAUDE.md 或规则文件路径
    3. 第 59-63 行: 填入你的外部审计 agent 名称
    4. 第 204-213 行: 替换 Preloaded Skills 为你的实际技能名

  改完后如何验证：
    - `wc -l ~/.claude/skills/dev-pipeline/SKILL.md` 确认文件已部署
    - `claude plugins list` 确认 dev-pipeline 出现在列表
    - 发起一个非平凡任务，确认流水线前 3 步被触发
  ================================================================
-->
---
name: dev-pipeline
description: Use when starting a new project, feature, or non-trivial task where error rate matters — determines which skills to invoke in which order, when to add dual-agent review, and how to match pipeline rigor to project risk level
---

# Development Pipeline

## Overview

12-step pipeline with 3 risk tiers. Each step catches a specific error class. Skip a step, and that class of error leaks through.

**Core principle:** Error rate = holes in the pipeline. Every error type needs a dedicated gate.

## Quick Reference

<!-- TODO(用户): 替换为你的实际 skill 名称。当前保留原文格式做参考。 -->

| Step | Skill (参考工具) | Catches | Risk: Low | Risk: Mid | Risk: High |
|------|------------------|---------|-----------|-----------|------------|
| 0 | `workspace-startup-audit` | Wrong mode (plan vs execute vs verify) | ✓ | ✓ | ✓ |
| 1 | `brainstorming` | Wrong direction (building wrong thing) | ✓ | ✓ | ✓ |
| 2 | `writing-plans` | Unscoped work (no verification criteria) | ✓ | ✓ | ✓ |
| 3 | `plan-eng-review` | Architecture gaps (missed edge cases) | — | ✓ | ✓ |
| 4 | `using-git-worktrees` | Workspace pollution (dirty main branch) | — | ✓ | ✓ |
| 5 | `test-driven-development` | Implementation bugs (logic errors) | — | ✓ | ✓ |
| 6 | Write code (Karpathy Guidelines active) | Over-engineering, unnecessary complexity | ✓ | ✓ | ✓ |
| 7 | `review` | Review-blind bugs (CI green but prod broken) | — | ✓ | ✓ |
| 8 | `simplify` | Code bloat, duplication, low-altitude patterns | — | ✓ | ✓ |
| 9 | `semgrep` | SAST vulnerabilities (injection, hardcoded secrets) | ✓ | ✓ | ✓ |
| 10 | `verification-before-completion` | Incomplete verification (assumed it works) | ✓ | ✓ | ✓ |
| ★ | 双代理互审 Gate ①+② | Architecture + delivery blind spots (见下方"双代理互审机制") | — | 按影响 | 按影响 |
| 11 | `ship` | Delivery chaos (version, changelog, merge conflicts) | — | ✓ | ✓ |
| 12 | `finishing-a-development-branch` | Branch garbage, stale worktrees | — | ✓ | ✓ |
| — | `handoff` | Context loss (handoff to next agent/session) | — | ✓ | ✓ |

## Risk Tiers

<!-- TODO(用户): 根据你的实际风险判定规则修改下表。影响分级参见你的 CLAUDE.md 或规则文件。 -->

| Tier | When | Pipeline | 双代理互审 |
|------|------|----------|-----------|
| **Low** | Scripts, config edits, one-off fixes | Steps 0-2, 6, 9-10 | 按影响分级触发 — 低影响无需互审 |
| **Mid** | Feature dev, hook modification, non-critical code | Full pipeline | 按影响分级触发 — 中影响 Gate ② 外部审计优先/降级 |
| **High** | Bridge/worker code, auth, funds, anything that takes down prod | Full pipeline | 按影响分级触发 — 高影响 Gate ①+② 外部审计硬闸门 |

## 双代理互审机制

<!-- TODO(用户): 修改为你的双代理互审规则文件路径。如果使用独立的 rules/dual-agent-audit.md，在这里引用。 -->

本 skill 的双代理互审逻辑由独立的规则文件统一管理（如 CLAUDE.md 或 rules/dual-agent-audit.md），此处仅保留 pipeline 集成点位。完整规则（影响分级、外部审计 agent 可用性检查、降级审查、紧急热修复、R1-R4 收敛）参见该规则文件。

**Gate ①（架构审计）**：plan-eng-review 之后、写代码之前。高影响变更触发。审计对象：架构评审输出 + 实现计划。

**Gate ②（交付审计）**：review + simplify + semgrep + verification 全部完成后、ship 之前。高/中影响变更触发。

**Bridge message format:** canonical request schema is `schema/audit-request.schema.json`; canonical response schema is `schema/audit-response.schema.json`.

```json
{
  "type": "audit_request",
  "gate": "gate_2",
  "version": "1.0",
  "round": 1,
  "payload": {
    "context": {
      "task": "Self-contained task description — external auditor cannot see your session history",
      "risk_level": "medium",
      "impact_domains": ["Skill / workflow creation"],
      "files_changed": ["examples/dev-pipeline-skill.md"]
    },
    "artifacts": {
      "diff": "Current diff or path to diff artifact",
      "verification_log": "Verification command output"
    }
  }
}
```

**External auditor returns:** `schema/audit-response.schema.json` with `result.verdict = PASS|BLOCKED` and findings carrying `severity`, `category`, `location`, `description`, and `suggestion`.

## The 3-Layer Architecture

```
┌─ Layer 3: Process Gates ──────────────────────────┐
│  When to proceed, when to stop                     │
│  plan-eng-review → [Gate ①] → ... → [Gate ②] → ship│
│  双代理互审：影响分级 + 双 Gate + 收敛协议            │
├─ Layer 2: Behavioral Constraints (always on) ──────┤
│  Think first → minimal → precise → verifiable       │
├─ Layer 1: Method Framework ────────────────────────┤
│  How to do things: brainstorm → plan → TDD → verify│
└────────────────────────────────────────────────────┘
```

## Decision Flow

```
New task received
  │
  ├─ Is this trivial? (typo, 1-line fix) → Just do it (behavioral constraints still active)
  │
  └─ Non-trivial →
       │
       ├─ workspace-startup-audit → Determine: plan / execute / review / verify?
       │
       ├─ brainstorming → What are we actually building? Challenge assumptions.
       │
       ├─ writing-plans → Break into verifiable tasks.
       │
       ├─ Risk assessment:
       │    Low → Steps 6, 9, 10. Done.
       │    Mid → Continue full pipeline.
       │    High → 按影响分级判定外部审计 Gate 触发。
       │
       ├─ plan-eng-review → Lock architecture. [Gate ① 架构审计: after this step, before code]
       │
       ├─ using-git-worktrees → Isolate workspace.
       │
       ├─ TDD → Write tests, watch them fail, write minimal code.
       │
       ├─ review + simplify → Hunt bugs, then hunt bloat.
       │
       ├─ semgrep → Machine-scanned vulnerability patterns.
       │
       ├─ verification-before-completion → Every item verified with command output. [Gate ② 交付审计: after this step, before ship]
       │
       ├─ ship → Merge base, test, version, changelog, PR.
       │
       ├─ finishing-a-development-branch → Clean up branch + worktree.
       │
       └─ handoff (if needed) → Compress context for next agent.
```

## Reasoning Steps (Why Each Step Exists)

### Step 0: workspace-startup-audit
**Problem:** Opening a directory and immediately coding, only to discover halfway through that the workspace was in "verify" mode or had partial artifacts.
**Solution:** Read CLAUDE.md/AGENTS.md, check for in-progress work, declare mode before acting. **Catches:** working in the wrong mode.

### Step 1: brainstorming
**Problem:** Building exactly what was asked for, only to discover it was the wrong thing. Implementation speed is wasted if the direction is off.
**Solution:** Explore intent, surface hidden assumptions, challenge scope, identify what NOT to build. Use this even for seemingly clear requests — clarity is often an illusion of shared but unstated context. **Catches:** building the wrong thing.

### Step 2: writing-plans
**Problem:** A vague task ("add auth") becomes an endless project because no one defined "done." Each sub-task spawns more sub-tasks without boundaries.
**Solution:** Break into concrete, verifiable tasks. Each task has a verification criterion. This creates a contract: when all verifications pass, the work IS done. **Catches:** scope creep, undefined completion criteria.

### Step 3: plan-eng-review
**Problem:** Code that works for the happy path but fails on edge cases discovered in production. Architecture decisions made implicitly during coding rather than explicitly before it.
**Solution:** Lock architecture with ASCII diagrams, enumerate edge cases, define data flow, check test coverage strategy. This is the last chance to change direction cheaply — after this, every change costs code. **Catches:** architecture-level edge cases, missing error states, implicit assumptions about data flow.

### Step 4: using-git-worktrees
**Problem:** Mid-feature, need to hotfix something on main. Or: experiment with an approach, it doesn't work, and now the working tree is polluted with half-baked changes.
**Solution:** Isolate each feature in its own worktree. Can switch contexts without stashing or committing half-done work. **Catches:** workspace pollution, context-switch overhead.

### Step 5: test-driven-development
**Problem:** Writing tests after code proves the code does what it does, not what it should do. Tests pass on first run because they validate the implementation, not the requirement.
**Solution:** Write test → watch it fail → write minimal code → watch it pass → refactor. The failing test IS the specification. **Catches:** tests that validate implementation instead of requirements.

### Step 6: Write code (behavioral constraints active)
**Problem:** LLMs over-engineer. They add abstractions for hypothetical futures, write 30 lines where 5 would do, and solve problems the user didn't ask about.
**Solution:** Four constraints always active: (1) Think before writing, (2) Minimal over clever, (3) Surgical changes — don't touch what doesn't need changing, (4) Every change must have a verifiable goal. **Catches:** over-engineering, unnecessary abstraction, scope expansion.

### Step 7: review
**Problem:** Standard code review catches style issues and obvious bugs. It misses the dangerous class: code that looks correct, passes tests, but fails in production under real-world conditions.
**Solution:** Paranoid staff-engineer perspective. Hunt for: race conditions, partial failure handling, state corruption, resource leaks, incorrect assumptions about ordering. **Catches:** "CI green but prod broken" bugs.

### Step 8: simplify
**Problem:** Review found bugs and fixed them. But the fixes added cruft. Over several review cycles, code accumulates redundant patterns, duplicated logic, and unnecessary indirection.
**Solution:** Hunt for: duplicated code, over-abstraction, dead code, low-altitude patterns that could be expressed more directly. This is quality-only — it does not hunt for bugs (review already did that). **Catches:** code bloat, duplication, unnecessary complexity.

### Step 9: semgrep
**Problem:** Human reviewers (and LLM reviewers) miss pattern-based vulnerabilities. Hardcoded secrets, SQL injection, XSS vectors — these don't look "wrong" to a reviewer reading logic, but a pattern engine catches them instantly.
**Solution:** Run automated SAST scan. Zero false-positive tolerance is not the goal — surface findings, triage quickly, suppress false positives. **Catches:** injection vulnerabilities, hardcoded credentials, dangerous patterns.

### Step 10: verification-before-completion
**Problem:** "I ran the tests, they passed" — but the tests didn't cover the specific change. Or: the change works in isolation but breaks something else. Self-reported success is unreliable.
**Solution:** For each task in the plan, run a specific verification command and compare output to expected output. Do not trust execution logs. Concrete, reproducible checks. **Catches:** incomplete verification, assumed-it-worked syndrome.

### Step 11: ship
**Problem:** Code is done, reviewed, verified. Then: merge conflicts with base branch, forgot to bump version, changelog is empty, push to wrong branch, PR description is a commit message.
**Solution:** Automated delivery pipeline: detect and merge base branch → run full test suite → review final diff → bump VERSION → update CHANGELOG → commit → push → create PR with proper description. **Catches:** delivery chaos.

### Step 12: finishing-a-development-branch
**Problem:** Feature is shipped. The branch and worktree linger. Three months later, there are 47 stale branches and 12 orphaned worktrees. Nobody knows which can be deleted.
**Solution:** Structured decision after ship: merge vs rebase vs cherry-pick, keep or delete worktree, archive or delete branch. **Catches:** branch/worktree garbage accumulation.

### Handoff (conditional)
**Problem:** Task needs to continue with another agent (next session or external auditor). The next agent has zero context from this session. It either redoes the work or makes decisions based on incomplete information.
**Solution:** Compress conversation into a handoff document with: current state, decisions made and why, remaining tasks, known pitfalls, verification criteria. **Catches:** context loss across agent/session boundaries.

## Common Mistakes

| Mistake | Reality |
|---------|---------|
| "This is simple, skip brainstorming" | Simple things hide assumptions. 5 min brainstorming saves hours of wrong implementation. |
| "I'll review my own code mentally" | Self-review has systematic blind spots. Always use external review. |
| "Tests pass, ship it" | Passing tests ≠ correct behavior. Always run verification-before-completion with specific checks. |
| "External audit is overkill" | For bridge/worker code that takes down prod, the cost of a missed bug dwarfs the cost of dual review. |
| "I'll clean up branches later" | You won't. Use finishing-a-development-branch immediately after ship. |
| "TDD slows me down" | Rework from untested code takes 10x longer than writing tests first. |
| "simplify and review are the same thing" | Review hunts bugs. Simplify hunts bloat. They need different mindsets. |

## Red Flags

- "I already know what to build" → Still run brainstorming. Known = assumed.
- "The architecture is obvious" → Still run plan-eng-review. Obvious things have the most hidden edge cases.
- "Tests pass on first run" → Your tests aren't testing the right thing. TDD requires watching tests FAIL first.
- "This doesn't need a worktree" → If you might need to switch contexts, you need a worktree.
- "I'll add tests after" → You won't. Or they'll validate implementation, not requirements.
- "I reviewed it myself" → Self-review is not review. Use automated review tools.
- "semgrep found nothing" → Good. But still run it — one finding justifies the 10 seconds it took.

## Preloaded Skills

<!-- TODO(用户): 替换为你的环境中实际安装的技能/工具名称。每个环境不同。 -->
<!-- 例如：如果使用 Claude Code CLI，技能名为 superpowers:brainstorming 等格式。 -->

This pipeline assumes these skills/tools are available and the environment knows how to invoke them. Adjust the names below to match your setup.

| Layer | Skills (参考工具) |
|-------|------------------|
| Method framework | `brainstorming`, `writing-plans`, `test-driven-development`, `verification-before-completion`, `using-git-worktrees`, `finishing-a-development-branch`, `dispatching-parallel-agents` |
| Process gates | `plan-eng-review`, `review`, `ship` |
| Built-in quality | `simplify`, `semgrep`, `handoff` |
| Workspace audit | `workspace-startup-audit` |
| Behavioral | `karpathy-guidelines` (always active) |

## 验证方法

部署后执行以下检查确认生效：

```bash
# 确认目标位置存在
wc -l ~/.claude/skills/dev-pipeline/SKILL.md

# 无源文件残留检查 — 确保无个人项目名或人名残留
grep -E "source-repo|personal-brand|private-package" ~/.claude/skills/dev-pipeline/SKILL.md && echo "FAIL: 有残留" || echo "OK: 已清理"

# 使用者自己的残留检查：确认无个人路径硬编码
grep -n "your-home\|your-" ~/.claude/skills/dev-pipeline/SKILL.md || echo "无待填占位符"
```
