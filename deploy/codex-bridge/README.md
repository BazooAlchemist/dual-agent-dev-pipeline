# Codex Bridge — Reference Deployment

> This is a **reference deployment guide** for a Codex-based external audit agent bridge, designed to work with the dual-agent audit protocol defined in `core/04-dual-agent-audit.md`. Tested on 1 environment (macOS 15 + Codex CLI 0.x). Not guaranteed for all macOS or Codex versions.

This README covers the manual deployment steps. Automated scripts in this directory (`setup-codex-bridge.sh`, `health-check.sh`) are provided as reference only. The canonical message contracts are `schema/audit-request.schema.json` and `schema/audit-response.schema.json`.

---

## 1. 前置条件 (Prerequisites)

Before deploying, ensure the following are installed and functional:

| Requirement | Version / Check | Notes |
|-------------|-----------------|-------|
| macOS | 14+ recommended | Only platform tested. Linux and Windows are not supported. |
| Node.js | >= 18 | `node --version` must return v18.x or later. |
| Claude Code CLI | latest | `claude --version` — used as the primary development agent. |
| Codex CLI | latest | `codex --version` — used as the external audit agent. |
| git | any modern version | `git --version` — for cloning the bridge worker. |
| launchd | built into macOS | Used to keep the bridge worker alive as a daemon. |

The bridge worker communicates with Codex by placing and polling task files in a shared inbox directory. No network daemon is required.

---

## 2. 部署步骤 (Deployment Steps)

Approximately 10-15 minutes.

### Step 1: Clone or locate a bridge worker

```bash
# If you have AgentFoundry installed:
ls $HOME/AI/AgentFoundry/setup/codex-bridge/worker.mjs

# Otherwise, clone the reference:
# git clone <your-agentfoundry-repo> $HOME/AI/AgentFoundry
```

The bridge worker is the script that launchd will run. This repository does not bundle that worker; it provides the launchd template, directory layout, health checks, and canonical schemas. If you do not have AgentFoundry, write or supply a polling script that watches a directory, validates `schema/audit-request.schema.json`, calls `codex` on incoming task files, and writes responses that match `schema/audit-response.schema.json`.

### Step 2: Create the bridge directories

```bash
mkdir -p $HOME/.openclaw/bridges/codex/{inbox,processing,done,failed,archive}
mkdir -p $HOME/.openclaw/logs
```

The inbox directory is where Claude Code places audit requests. The bridge worker polls this directory, invokes Codex on each task, and moves results to `done/` or `failed/`.

### Step 3: Configure environment variables

The bridge worker needs two environment variables:

```bash
export AGENTFOUNDRY_ROOT="$HOME/AI/AgentFoundry"
export CODEX_BRIDGE_ROOT="$HOME/.openclaw/bridges/codex"
```

Add these to your shell profile (`$HOME/.zshrc` or equivalent) for persistence:

```bash
echo 'export AGENTFOUNDRY_ROOT="$HOME/AI/AgentFoundry"' >> $HOME/.zshrc
echo 'export CODEX_BRIDGE_ROOT="$HOME/.openclaw/bridges/codex"' >> $HOME/.zshrc
```

### Step 4: Create the launchd plist

Copy the reference plist template from this directory:

```bash
install -d "$HOME/Library/LaunchAgents"
install -m 0644 deploy/codex-bridge/codex-bridge-launchd.plist "$HOME/Library/LaunchAgents/ai.openclaw.codex-bridge.plist"
```

Edit the plist to replace the following placeholders:

| Placeholder | Replace with |
|-------------|-------------|
| `<your-home>` | Your home directory path (output of `echo $HOME`) |
| `<your-agentfoundry-root>` | `$HOME/AI/AgentFoundry` (or wherever you placed the worker) |
| `/path/to/node` | Output of `which node` |

### Step 5: Load the launchd service

```bash
launchctl bootstrap gui/$(id -u) $HOME/Library/LaunchAgents/ai.openclaw.codex-bridge.plist
```

### Step 6: (Optional) Configure Claude Code to use the bridge

In your `~/.claude/settings.json`, add a post-tool or pre-commit hook that writes audit requests to the inbox directory. See `examples/settings.json.example` for a template, `core/04-dual-agent-audit.md` for the protocol, and `schema/audit-request.schema.json` / `schema/audit-response.schema.json` for the exact message contracts.

---

## 3. 验证方法 (Verification)

After deployment, run these checks:

```bash
# Check the process is running
launchctl list | grep codex-bridge

# Expected output (PID will differ):
# 12345  0  ai.openclaw.codex-bridge

# Check logs for startup confirmation
tail -5 $HOME/.openclaw/logs/codex-bridge.out.log

# Check the inbox is writable
touch $HOME/.openclaw/bridges/codex/inbox/.test-write && rm $HOME/.openclaw/bridges/codex/inbox/.test-write
echo "Inbox is writable"

# Run the health check script (if deployed)
bash deploy/codex-bridge/health-check.sh
```

To verify end-to-end functionality:

1. Place a valid audit request JSON file into `$HOME/.openclaw/bridges/codex/inbox/`.
2. Wait 10-30 seconds for the bridge worker to pick it up.
3. Check `$HOME/.openclaw/bridges/codex/done/` for the response.
4. Check `$HOME/.openclaw/bridges/codex/failed/` if no response appears.

---

## 4. 排障 (Troubleshooting)

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `launchctl list | grep codex-bridge` shows nothing | Service not loaded or crashed | Run `launchctl bootstrap gui/$(id -u) ...` again. Check `codex-bridge.err.log`. |
| `launchctl list` shows non-zero exit code in the second column | Worker script path is wrong or Node.js not found | Verify `which node` returns a path and the plist's `ProgramArguments` points to the correct worker. |
| Inbox files are not picked up | Directory permissions or bridge poll interval | Ensure `$CODEX_BRIDGE_ROOT/inbox/` is readable by the user running launchd. The worker polls every 5 seconds by default. |
| Codex audit returns empty or malformed results | Codex CLI not installed or misconfigured | Run `codex --version` to confirm it works. Check `codex-bridge.err.log` for Codex invocation errors. |
| Bridge starts but stops after a few minutes | launchd KeepAlive misconfiguration | Verify the plist has `<key>KeepAlive</key><true/>`. |
| Permission denied writing to inbox | Bridge directory owned by wrong user | Ensure `$HOME/.openclaw/bridges/codex/` and all subdirectories are owned by your user. |

If none of these resolve the issue, enable verbose logging by adding `--verbose` to the worker arguments in the plist, then reload the service and inspect the logs.

---

## 5. 限制 (Limitations)

| Dimension | Limitation |
|-----------|-----------|
| Platform | **macOS only.** The launchd plist format is macOS-specific. Linux users need systemd or a similar init system. Windows is not supported. |
| External audit agent | **Codex only.** This bridge is written for Codex CLI. Using a different agent (e.g., Claude Code as auditor, OpenAI CLI) requires rewriting the worker script. |
| Environments verified | **1** (macOS 15, Codex CLI 0.x, Node.js 22). The reference scripts carry a `[reference]` tag and are not guaranteed on other configurations. |
| Codex version coverage | The bridge worker calls `codex` as a CLI subprocess. Breaking changes in Codex CLI arguments or output format may require worker updates. |
| Concurrent audit requests | The bridge worker processes **one task at a time** (sequential polling). High-throughput environments should implement concurrent processing in the worker. |
| Network isolation | The bridge does not expose a network endpoint. Audit requests are file-based, meaning both agents must share a filesystem. |
| Security | The bridge does not encrypt task files. If multi-user access to the inbox is required, consider adding file encryption or moving to a network-based bridge. |

---

**Next:** For a deeper understanding of the audit protocol and message schemas, see `../../core/04-dual-agent-audit.md`. For configuration templates, see `../../examples/settings.json.example`. For a quick-start walkthrough of the full pipeline, see `../../QUICKSTART.md`.
