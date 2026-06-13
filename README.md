# Dual-Agent Dev Pipeline

> A battle-tested AI-assisted development pipeline methodology + Codex reference implementation for Claude Code CLI.

## Bilingual Summary / 中英双语摘要

**EN:** This repository provides a structured development pipeline designed specifically for AI-assisted coding workflows. It contains 18 files across 4 layers: core methodology (tool-agnostic), adapter guides (tool-specific mappings), annotated configuration examples, and a Codex bridge reference implementation for cross-model audit. The pipeline prevents the class of errors LLMs are most prone to — skipping diagnosis, over-engineering, ignoring the root cause — by enforcing 12 steps guarded by two independent audit gates. Each step is designed to catch one category of error; skipping one means accepting that category.

**CN:** 本仓库提供一套专门为 AI 辅助编码设计的分阶段开发流水线。共 18 个文件、4 个层级：核心方法论（与工具无关的通用规则）、适配器指南（具体工具的能力映射）、带注释的配置示例、以及基于 Codex 的双模型互审参考实现。该流水线通过 12 个步骤 + 两道独立审计闸门，系统性防范 LLM 最常见的错误类型——跳过诊断、过度设计、忽视根因。每步防一类错误，跳一步 = 接受该类错误。

## Repository Structure

```
dual-agent-dev-pipeline/
|
|-- README.md               Entry point (this file)
|-- PHILOSOPHY.md           Design philosophy & why this pipeline exists
|-- QUICKSTART.md           5-step minimal onboarding (~30 min)
|
|-- core/                   Methodology — tool-agnostic, portable to any AI coding tool
|   |-- 01-pipeline-overview.md        12-step pipeline panorama & decision flow
|   |-- 02-pipeline-steps.md           Detailed step walkthroughs, rationale, common mistakes
|   |-- 03-risk-tiers.md               Low / Mid / High risk tier definitions & escalation rules
|   |-- 04-dual-agent-audit.md         Dual-agent cross-audit protocol (capability-trigger based)
|   |-- 05-three-layer-architecture.md 3-layer architecture: Method / Behavior / Process Gates
|
|-- adapters/               Tool mappings — how capabilities map to concrete tools
|   |-- tool-mapping-table.md          Capability -> reference tool -> alternative mapping table
|   |-- claude-code.md                 Onboarding guide for Claude Code CLI
|   |-- codex-auditor.md               Interface definition for Codex as external audit agent
|
|-- examples/               Annotated config examples — copy, edit, deploy
|   |-- CLAUDE.md.example
|   |-- dev-pipeline-skill.md
|   |-- governance-dual-audit.md
|   |-- settings.json.example
|
|-- deploy/                 Runtime reference implementations ([reference] — tested on 1 env)
|   |-- codex-bridge/
|       |-- README.md                   Manual deployment steps
|       |-- setup-codex-bridge.sh       [reference] Setup script
|       |-- health-check.sh             [reference] Health check script
|       |-- codex-bridge-launchd.plist  launchd plist template
|
|-- appendix/               Non-normative appendices
|   |-- real-world-cases.md            Anonymized real-world case studies (3 sub-cases)
|   |-- file-trigger-examples.md       File-based trigger examples (illustrative only)
```

## Three Entry Paths / 三条入口

Choose the path that matches your goal:

**Entry A — "I want to understand the methodology"**
`README` -> `PHILOSOPHY.md` -> `core/01-pipeline-overview.md` -> `core/04-dual-agent-audit.md`
Ideal for architects and team leads evaluating whether this approach fits their workflow.

**Entry B — "I want the minimal working setup in ~30 minutes"**
`README` -> `QUICKSTART.md` -> `examples/CLAUDE.md.example` -> `examples/governance-dual-audit.md`
Ideal for individual developers ready to adopt the pipeline immediately.

**Entry C — "I want to deploy the full Codex reference implementation"**
Entry B first -> `deploy/codex-bridge/README.md` -> (optional) `deploy/codex-bridge/*.sh`
Adds the cross-model audit agent for automated Gate audits.

## Prerequisites

- macOS (launchd-based service management)
- Claude Code CLI (for pipeline execution)
- Node.js >= 18 (for Codex bridge)
- git (for version control)
- (Optional) Codex CLI — for dual-agent audit setup via Entry C

## Quick Start

See [QUICKSTART.md](./QUICKSTART.md) for a 5-step minimal onboarding path (~30 minutes target time, actual time may vary).

## License

[MIT](./LICENSE)

## Boundary Statement / 边界声明

**In scope:**
- AI-assisted development pipeline methodology for Claude Code CLI + Codex
- Risk tier classification and dual-agent cross-audit protocol
- Annotated configuration templates (CLAUDE.md, settings.json, governance rules, dev-pipeline skill)
- Codex bridge reference implementation for macOS deployment

**Out of scope / 不解决什么:**
- This is **not** a general-purpose CI/CD pipeline. It is specifically designed for AI-assisted code generation workflows.
- The deploy scripts are **reference implementations** tested on a single environment. They may require adjustment for your specific setup.
- The pipeline does **not** replace security audits, unit test coverage requirements, or manual code reviews.
- Non-macOS platform deployment is not covered. Windows and Linux users will need to adapt the launchd plist and shell scripts to their platform equivalents.
- The methodology does **not** guarantee zero bugs. It reduces the probability of LLM-pattern errors through systematic gating.

## Return Path

Questions, issues, or contributions? Open an issue or pull request in this repository.
