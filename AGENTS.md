# Agent Workflow Rules

This repository documents and demonstrates a dual-agent development pipeline. Agents working in this repo should use the same discipline the repo recommends.

## Startup

- Read this file, `README.md`, and the relevant `core/` document before changing behavior.
- Use `/Users/wangyun/.local/bin/codegraph` as the canonical CodeGraph binary on this machine.
- Run `codegraph status <project>` before relying on CodeGraph. This repo is mostly Markdown and shell, so CodeGraph may have zero indexed nodes; use `rg` for literal documentation searches.
- Treat `.codegraph/` as a local cache. Do not commit it or manually edit database files.

## Risk Tiering

- Low: typo fixes, formatting, pure non-governance prose. Use scoped edits plus validation.
- Mid: schema, quickstart, examples, scripts, governance additions, or workflow documentation. Use a written plan, test-first validation, and full repo validation.
- High: changes that weaken gates, alter audit severity rules, change external auditor requirements, or change bridge protocol semantics. Require external audit before delivery when available.

## Working Rules

- For non-trivial changes, write or update a plan under `docs/superpowers/plans/`.
- Prefer test-first changes. For this documentation repo, `scripts/validate-repo.sh` is the regression test harness.
- Keep one canonical audit request schema and one canonical audit response schema under `schema/`; examples must reference those files instead of inventing local variants.
- Do not overwrite user configuration in examples. Quickstart commands must create directories, preserve existing files, or instruct the user to merge.
- Before claiming completion, run `bash scripts/validate-repo.sh` and inspect the output.

## Delivery

- Keep commits scoped by boundary: workflow rules, schemas, docs, scripts.
- Do not push unless the user explicitly asks.
- Report any skipped verification with the reason and the residual risk.
