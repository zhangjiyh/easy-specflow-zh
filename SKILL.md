---
name: easy-specflow-zh
description: 面向 AI 编码客户端的中文长任务工作流仓库，使用统一的 spec -> plan -> execute -> verify -> accept 规则和 .specflow/ 目录推进任务。
---

# easy-specflow-zh

这是一个中文长任务工作流 skill / workflow repository。

适用对象：

1. Codex
2. Claude Code
3. OpenCode
4. 其他愿意读取仓库规则、模板和状态文件的 AI 编码客户端

## 先读哪些文件

开始工作前，优先按下面顺序读取：

1. `README.md`
2. `rules/workflow.md`
3. `rules/stage-transition.md`
4. `templates/`
5. `prompts/`

如果已经存在任务目录，再读取：

1. `<project-root>/.specflow/index.json`
2. 当前任务目录中的 `state.json`
3. `任务说明.md`
4. `执行计划.md`
5. `进度记录.md`
6. `验收记录.md`

## 默认工作目录

默认任务工作目录固定为：

```text
<project-root>/.specflow/
```

任务目录格式固定为：

```text
.specflow/tasks/TYYYYMMDD-001-任务标题/
```

## 工作流要求

任务推进必须遵循统一顺序：

`spec -> plan -> execute -> verify -> accept`

各阶段的最低要求：

1. `spec`：明确目标、范围、限制和验收标准，更新 `任务说明.md`。
2. `plan`：拆出可执行步骤、风险点和验证方法，更新 `执行计划.md`。
3. `execute`：按计划推进实现，并把过程和结果写入 `进度记录.md`。
4. `verify`：对照需求与计划做检查，把验证结论写入 `进度记录.md`。
5. `accept`：形成最终结论与遗留事项，更新 `验收记录.md`。

## 强制流程护栏

1. 不要一次性伪造完成全部五阶段；默认只推进当前阶段所需的真实动作。
2. `execute` 阶段一次只推进一个明确步骤；步骤完成后必须立即勾选 `执行计划.md` 中对应项。
3. 只要 `执行计划.md` 仍有未勾选步骤，就不得进入 `verify` 或 `accept`。
4. `verify` 阶段如果发现未通过项、环境阻塞或待补验证，必须保持 `status=active`，并明确写回 `进度记录.md`。
5. 只有当以下条件同时满足时，才允许将 `state.json.status` 标记为 `done`：
   - `执行计划.md` 没有未勾选步骤。
   - `任务说明.md` 中的验收标准已按结果回填。
   - `验收记录.md` 中的关键检查全部通过。
   - 没有“无阻塞上线的问题”这一项的未通过情况。
   - 最终结论为“通过”，而不是“有条件通过”或“不通过”。
6. 如果结论是“有条件通过”或仍存在阻塞，只能把任务收敛到 `accept`，不能写 `done`。
7. `state.json` 是当前任务阶段和状态的唯一事实来源；文档里的阶段字段只表示文档所属阶段，不表示当前任务实时状态。

## 状态更新要求

每次推进任务时，都要同步更新当前任务目录下的 `state.json`：

1. `stage`：当前阶段。
2. `status`：推荐使用 `active / done / archived / deleted`。
3. `updatedAt`：最近更新时间。
4. `lastAction.agent`：本次操作的 agent 名称。
5. `lastAction.summary`：本次操作摘要。
6. 如果任务仍有阻塞、未完成步骤或待补验证，不要写 `status=done`。

## 跨 agent 协作要求

1. 所有 agent 共用同一个 `.specflow/` 目录。
2. 不为不同平台复制一套独立任务结构。
3. 不新增平台专属适配层，除非确有必要。
4. 所有阶段产出都以仓库文件为准，不以聊天上下文为准。
5. 如果发现当前任务状态与文档不一致，先修正文档和 `state.json`，再继续执行。

## 可直接使用的脚本

```bash
bash scripts/init-workflow.sh
bash scripts/specflow.sh new "任务标题"
bash scripts/status.sh
bash scripts/next-step.sh
bash scripts/verify.sh
```

`agents/openai.yaml` 仅提供极简元信息；真正的入口仍然是本文件和仓库中的规则、模板、提示词与脚本。
