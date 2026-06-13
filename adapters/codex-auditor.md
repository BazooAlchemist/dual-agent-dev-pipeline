# Codex 外部审计 agent 接口定义

本文档定义如何将 Codex（或任何不同模型提供商的独立 agent）作为双代理互审机制的外部审计 agent 使用。它是 `core/04-dual-agent-audit.md` 中定义的审计协议的 Codex 特定落地指南。

---

## ① 能力映射

| 能力 | 参考工具 | 可替代方案 |
|------|---------|-----------|
| 外部独立审计 | Codex（Anthropic 之外的模型提供商 agent） | 任何非当前执行 agent 的独立 agent |
| 架构建模审查 | Codex 执行 Gate ① — 评审架构合理性、是否跳过简单根因 | 人工架构评审会 |
| 交付质量审计 | Codex 执行 Gate ② — 检查交付物与计划的一致性、端到端验证 | 人工 QA 验收 |
| 收敛过程 | Codex 逐步验证修复，支持 R1–R4 最多 4 轮收敛 | 多轮人工审查 |

核心原则：审计 agent **必须**与执行 agent 来自**不同模型提供商**。如果执行 agent 是 Claude（Anthropic），外部审计 agent 应使用 GPT、Gemini 或其他非 Anthropic 模型，不可使用同一提供商的不同模型。

---

## ② 适用前提

使用 Codex 作为外部审计 agent 前，需要满足以下条件：

1. **已部署 Codex bridge**：能够通过 inbox/processing/done 目录结构向 Codex 发送任务并收取结果。部署步骤见 `deploy/codex-bridge/README.md`。
2. **Codex 可访问目标仓库**：Codex 需要运行在能够读取目标仓库代码的环境中。
3. **审计 agent 的模型配置**：外部审计 agent 应使用与执行 agent 不同的模型提供商（例如执行用 Claude → 审计用 GPT-4o）。
4. **桥接消息格式一致**：发起审计的 message JSON schema 必须符合 `core/04-dual-agent-audit.md` 中定义的核心结构。

### 发起审计

通过 bridge 发送审计请求。message JSON 核心结构如下（完整 schema 见 `core/04-dual-agent-audit.md`）：

```json
{
  "messageType": "audit-request",
  "auditGate": "gate-1 | gate-2",
  "convergenceRound": 1,
  "context": {
    "taskDescription": "本次任务的一句话描述",
    "changedFiles": ["src/handler.py", "src/schema.json"],
    "changedCapabilityDomains": ["桥接协议", "业务逻辑处理"],
    "riskTier": "high | mid | low",
    "planSummary": "架构/计划的摘要（Gate ①）或交付物变更摘要（Gate ②）"
  }
}
```

### 解读结果

审计结果通过 bridge 返回，使用以下判定 schema：

| 字段 | 值 | 含义 |
|------|-----|------|
| `verdict` | `PASS` | 审计通过，无需修改 |
| `verdict` | `BLOCKED` | 审计不通过，需要修改 |
| `items[].type` | `BLOCKER` | 必须修复才能继续 |
| `items[].type` | `FIX` | 建议修复（非阻塞） |
| `items[].type` | `NOTE` | 观察记录（无需修复） |

每条审计项包含定位描述和修复建议：

```json
{
  "verdict": "BLOCKED",
  "items": [
    {
      "type": "BLOCKER",
      "location": "src/handler.py:42",
      "description": "缺少输入校验，未处理空值情况",
      "suggestion": "添加 None 检查和默认值回退逻辑"
    }
  ],
  "summary": "发现 1 个 BLOCKER，需要修复后重新提交审计"
}
```

---

## ③ 收敛流程

审计 → 修复 → 重新审计的迭代过程，最多 4 轮：

| 轮次 | 内容 | 判定 |
|------|------|------|
| **R1** | 初始审计：外部 agent 审查架构/交付物，返回判定 | PASS → 继续；BLOCKED → 进入 R2 |
| **R2** | 修复验证：执行 agent 修复 BLOCKER，重新提交审计 | PASS → 继续；BLOCKED → 进入 R3 |
| **R3** | 追加修复：执行 agent 继续修复，第三方再次审查 | PASS → 继续；BLOCKED → 进入 R4 |
| **R4** | 最终判定：仍 BLOCKED 则升级到用户决策 | 用户决定：放行或回退 |

每轮审计请求的 `convergenceRound` 字段递增。到达 R4 仍然 BLOCKED 时，不再自动迭代，等待人工判定。

---

## ④ 替代方案

如果 Codex 不可用或不符合场景要求，可以使用以下替代方案：

| 替代方案 | 适用场景 | 成本 |
|---------|---------|------|
| **其他模型提供商的 agent**（如 GPT CLI、Gemini CLI） | 有另一套 LLM CLI 工具 | 中 — 需要适配 bridge 接口 |
| **人工代码审查**（GitHub PR Review、Gerrit） | 有审查团队成员 | 低 — 替换为人工流程即可，不需要 bridge |
| **自定义审计脚本**（规则检查、lint、SAST） | 只需要自动化规则检查，不需要 LLM 判定 | 低 — 规则固定，无需 LLM |

### 可替换为其他 agent 的最小接口

任何替代外部审计 agent 必须满足以下接口要求：

**输入（审计请求）**：
- 接收审计上下文：任务描述、变更文件列表、影响能力域、风险层级、计划/变更摘要
- 接收当前收敛轮次编号

**输出（审计结果）**：
- 返回审判判定（PASS / BLOCKED）
- 返回审计项列表，每项包含类型（BLOCKER / FIX / NOTE）、定位、描述、修复建议
- 返回汇总说明

**行为约束**：
- 最高 4 轮收敛，超过后升级到人工决策
- 审计 agent 不能参与代码修改（不能既是审计者又是执行者）
- 审计判定不可绕过（用户显式 break-glass 除外——见 `core/04-dual-agent-audit.md`）

---

下一篇：`../examples/dev-pipeline-skill.md` — 查看完整的 dev-pipeline skill 配置示例。
