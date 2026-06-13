# Claude Code CLI 落地指南

## 能力映射

本仓库的流水线方法论（core/）以**能力名**定义每一步。以下是在 Claude Code CLI 上，能力名到具体工具的映射。完整映射表见 `tool-mapping-table.md`。

| 能力 | Claude Code 工具 | 说明 |
|------|----------------|------|
| 模式判定 | workspace-startup-audit skill | 首次加载 workspace 时自动运行仓库扫描 |
| 需求探索 | superpowers:brainstorming | 结构化多角度方案探索流程 |
| 规划书写 | superpowers:writing-plans | 方案文档的模板化书写 |
| 架构审查 | gstack:plan-eng-review | 架构设计的结构化审查流程 |
| 测试驱动开发 | superpowers:test-driven-development | 先写测试再写实现的迭代循环 |
| 代码简化 | `simplify` 命令 | 自动化代码简化与冗余清理 |
| 代码审查 | `review` 命令 / `gstack:review` | 当前 diff 的自动化审查 |
| 安全扫描 | `semgrep` MCP 工具 | SAST 扫描（需配置 MCP server） |
| 外部独立审计 | Adobe Codex (via codex-bridge) | 不同模型提供商的独立 agent 做交付审计 |
| 并行分派 | superpowers:dispatching-parallel-agents | 将独立子任务分派给多个 agent |
| 交付自动化 | gstack:ship | 分支清理、PR 创建、合并的自动化 |
| 完成验证 | superpowers:verification-before-completion | 交付前的全维度验证检查 |

## 适用前提

使用 Claude Code CLI 落地本流水线需要以下环境就绪：

1. **Claude Code CLI**：已安装并通过 `claude` 命令可用。确认版本：
   ```shell
   claude --version
   ```

2. **settings.json 配置**：`~/.claude/settings.json` 已就绪。关键配置项包括：

   - **MCP servers**：注册 semgrep 等第三方安全扫描工具
   - **Hooks**：配置 pre-commit、post-tool 等自动化钩子
   - **Permissions**：允许/禁止特定命令的权限规则

3. **技能（Skills）安装**：流水线依赖以下技能，需通过 `claude plugins install` 安装：
   - `superpowers` 系列（brainstorming, writing-plans, test-driven-development, dispatching-parallel-agents, verification-before-completion）
   - `gstack` 系列（plan-eng-review, review, ship）
   - `workspace-startup-audit`（模式判定）

   安装命令示例：
   ```shell
   claude plugins install superpowers
   claude plugins install gstack
   claude plugins install workspace-startup-audit
   ```

4. **semgrep MCP**：SAST 扫描依赖 Semgrep MCP server：
   ```shell
   claude mcp add semgrep -- npx -y @semgrep/mcp
   ```

5. **Codex bridge**（可选）：如需双代理互审中的外部审计能力，需额外部署 Codex bridge。详见 `deploy/codex-bridge/README.md`。

## 替代方案

不使用 Claude Code CLI 时，每项能力的等效替代工具：

| 能力 | Claude Code 工具 | 替代方案 |
|------|-----------------|---------|
| 代码简化 | simplify 命令 | 手动重构、ESLint 规则、Prettier |
| 代码审查 | review 命令 | GitHub PR review、Gerrit、GitLab MR review |
| 安全扫描 | semgrep MCP | CodeQL、SonarQube、Snyk CLI |
| 架构审查 | gstack:plan-eng-review | 人工架构评审会议、RFC 文档流程 |
| 外部审计 | Codex via codex-bridge | 任何不同模型提供商的独立 agent |
| 方法框架 | superpowers:* | 自建等效流程（等效 checklist） |

不依赖 Claude Code 的环境可以只取 `core/` 的方法论，自行适配到所用工具。

---

下一篇：`codex-auditor.md` — Codex 作为外部审计 agent 的接口定义
