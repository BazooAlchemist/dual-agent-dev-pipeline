# 工具映射表

## 能力映射

以下表格将流水线 12 步的每项能力映射到参考工具及其可替代方案。工具是参考实现——所有能力都可以用等效流程替换。

| 步骤 | 能力 | 参考工具 | 可替代方案 | 替代成本 |
|------|------|---------|-----------|---------|
| 0 | 工作区模式判定 | workspace-startup-audit | 自建 checklist、手动读取 CLAUDE.md | 低 |
| 1 | 需求探索 | brainstorming | 人工需求讨论、用户故事映射 | 低 |
| 2 | 方案规划 | writing-plans | 自建计划模板、Jira/Linear ticket 拆解 | 低 |
| 3 | 架构审查 | plan-eng-review | 人工架构评审、RFC 流程、ADR 记录 | 低 |
| 4 | 工作树隔离 | using-git-worktrees | git branch + stash、手动分支管理 | 低 |
| 5 | 测试驱动开发 | test-driven-development | 先写代码后补测试（不推荐）、传统 TDD 流程 | 中（引入测试滞后风险） |
| 6 | 编写代码 | Karpathy Guidelines | 人工编码规范、ESLint/Prettier 等 lint 工具 | 中（依赖开发者自律） |
| 7 | 代码审查 | review | GitHub PR Review、Gerrit、GitLab MR Review | 低 |
| 8 | 代码简化 | simplify | 手动代码重构、SonarQube 代码异味检查 | 低 |
| 9 | 自动化 SAST | semgrep | CodeQL、SonarQube、Snyk、Trivy | 低（仅需替换扫描工具配置） |
| 10 | 验证确认 | verification-before-completion | 手动测试 + 检查清单 | 低 |
| 11 | 交付与收尾 | ship + finishing-a-development-branch | 手动 git 操作、自定义 CI/CD 脚本 | 低 |

**能力名约定**：所有流水线文档（core/ 系列）使用上表的能力名列作为标准名称，参考工具仅在括号中标注。例如："架构审查（参考工具：plan-eng-review）"。

## 适用前提

使用上表中的参考工具之前，需满足以下条件：

- **Claude Code CLI**：已安装并登录。所有 superpowers/*、gstack:* 类技能需要 `claude plugins install` 安装。
- **semgrep**：MCP server 已配置（`npx -y @semgrep/mcp`），或作为独立 CLI 可用。
- **git worktree**：Git 版本 >= 2.5（2015 年后的版本均满足）。
- **外部审计 agent**（高影响任务需要）：一个独立于当前执行 agent 的 AI 编码 agent（如 Codex CLI），满足 `adapters/codex-auditor.md` 定义的最小接口。

如果不使用任何参考工具，流水线仍然可以运行——只需为每项能力选择一个可替代方案并坚持执行。

## 替代方案说明

所有能力的替代成本标记为"低"或"中"。没有标记为"高"的项，因为流水线的核心是方法论而非特定工具：

- **低成本替代**：替换为人工流程或其他成熟工具即可，不影响流水线效果。
- **中等成本替代**：替换后可能降低效率或引入质量风险（如跳过 TDD 工具但保留"先测试"原则，需要更强的自律）。

**工具选择决策树**：

```
开始 → 团队已使用某种工具？ → 是 → 映射到对应能力继续
  ↓ 否
  → 该能力对当前任务关键？ → 是 → 从参考工具中选择一个
  ↓ 否                                  ↓ 否
  → 使用低成本替代方案                   → 省略该步骤（注意：跳步 = 漏错）
```

## 下一篇

继续阅读 `claude-code.md` —— Claude Code CLI 上每项能力的具体落地命令和配置方法。需要了解外部审计 agent 接口，请阅读 `codex-auditor.md`。
