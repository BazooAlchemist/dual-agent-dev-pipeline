# Repository Polishing Plan

This plan turns the repository from a strong methodology package into an easier-to-adopt workflow kit. It follows the repo's own pipeline: risk tier first, plan before edits, test-first validation, then verification before completion.

## Risk Tier

Current polishing work is **Mid impact**:

- It changes schemas, quickstart commands, examples, scripts, and governance wording.
- It does not weaken audit gates or change severity semantics.
- It needs a written plan and repository validation before delivery.

## P0: Adoption Safety

Status: implemented in this branch.

- Add repo-local agent rules in `AGENTS.md` so future agents use the same workflow discipline the repo recommends.
- Add `.codegraph/` to `.gitignore` so local CodeGraph cache files stay local.
- Add `scripts/validate-repo.sh` as a repeatable repository validation harness.
- Make Quickstart commands create directories and preserve existing user config before merge.

## P0: Canonical Audit Contract

Status: implemented in this branch.

- Add `schema/audit-request.schema.json`.
- Add `schema/audit-response.schema.json`.
- Update core, adapter, governance, and skill example docs to reference the schema files.
- Remove divergent example fields such as `messageType`, `auditGate`, `convergenceRound`, `riskTier`, and `audit_type`.

## P0: Reference Deployment Honesty

Status: implemented in this branch.

- Reword bridge docs from "reference implementation" to "reference deployment guide/helpers" where the worker is not bundled.
- Make `setup-codex-bridge.sh` create bridge directories, log directories, and the LaunchAgents target directory.
- Make `health-check.sh` return a non-zero exit code when required bridge state is missing.

## P1: Next Repository Pass

Recommended next changes:

- Add a minimal bridge worker fixture or explicitly move worker implementation out of scope in every deploy document.
- Add CI that runs `bash scripts/validate-repo.sh`, Markdown link checks, and JSON schema parsing on pull requests.
- Add one valid request fixture and one valid response fixture under `examples/audit-messages/`.
- Add a link checker so docs cannot drift from renamed files.

## P2: Adoption Experience

Recommended later changes:

- Add a 15-minute adoption path for users who only want the methodology.
- Add a 60-minute adoption path for users who want Claude Code rules without a bridge.
- Add a full dual-agent path for users deploying an external auditor.
- Add a troubleshooting matrix for schema mismatch, bridge worker absence, and unavailable external auditors.

## Verification Standard

Before claiming a polishing pass is complete, run:

```bash
bash scripts/validate-repo.sh
node -e "for (const f of ['schema/audit-request.schema.json','schema/audit-response.schema.json']) JSON.parse(require('fs').readFileSync(f,'utf8')); console.log('JSON OK')"
git diff --check
```
