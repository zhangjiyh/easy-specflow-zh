---
name: easy-specflow-zh
description: 面向 AI 编码客户端的中文长任务执行协议仓库，使用统一的 spec -> repo-map -> plan -> execute -> verify -> accept 规则和 .specflow/ 目录推进任务。
---

# easy-specflow-zh

这是一个中文长任务执行协议 skill / workflow repository。

适用对象：

1. Codex
2. Claude Code
3. OpenCode
4. 其他愿意读取仓库规则、模板和状态文件的 AI 编码客户端
5. 人工协作与多人接力场景

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
4. `代码库地图.md`
5. `执行计划.md`
6. `进度记录.md`
7. `验证记录.md`
8. `验收记录.md`

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

`spec -> repo-map -> plan -> execute -> verify -> accept`

各阶段的最低要求：

1. `spec`：明确目标、范围、限制和验收标准，更新 `任务说明.md`。
2. `repo-map`：确认真实代码边界、关键目录、入口文件、直接相关文件和潜在影响面，更新 `代码库地图.md`。
3. `plan`：拆出可执行步骤、修改范围、验证方式和完成标准，更新 `执行计划.md`。
4. `execute`：按计划连续推进实现，默认从 Step 1 执行到 Step N，直到全部已承诺步骤完成或遇到阻塞，并把过程、影响文件、验证命令与结果写入 `进度记录.md`。
5. `verify`：汇总结构化验证证据，说明做了什么验证、结果如何、还有哪些待补项，更新 `验证记录.md`。
6. `accept`：基于前序证据形成最终结论与遗留事项，更新 `验收记录.md`。

## 强制流程护栏

1. 不要一次性伪造完成全部六阶段；默认只推进当前阶段所需的真实动作。
2. `repo-map` 是正式阶段，不要把它降级成一句“先搜一下相关文件”。
3. `执行计划.md` 中每个关键步骤都必须写清验证方式和完成标准。
4. `execute` 阶段默认连续推进剩余已承诺步骤；每完成一步都要立即勾选 `执行计划.md` 中对应项，并补全 `进度记录.md`，但不要因为单步完成就默认中断整轮执行。
5. 对用户沟通默认采用“执行到底再统一总结”；只有遇到阻塞、高风险决策、权限不足或用户明确要求逐步确认时，才在中途停下来。
6. `verify` 阶段如果发现未通过项、环境阻塞或待补验证，必须保持 `status=active`，并明确写回 `验证记录.md`。
7. `accept` 必须基于 `任务说明.md`、`代码库地图.md`、`执行计划.md`、`进度记录.md`、`验证记录.md` 已存在的事实与证据给出结论。
8. 只有当以下条件同时满足时，才允许将 `state.json.status` 标记为 `done`：
   - `执行计划.md` 没有未勾选步骤。
   - `任务说明.md` 中的验收标准已按结果回填。
   - `验证记录.md` 中没有待补验证项或未关闭失败项。
   - `验收记录.md` 中的关键检查全部通过。
   - 最终结论为“通过”，而不是“有条件通过”或“不通过”。
9. 如果结论是“有条件通过”或仍存在阻塞，只能把任务收敛到 `accept`，不能写 `done`。
10. `state.json` 是当前任务阶段和状态的唯一事实来源；文档里的阶段字段只表示文档所属阶段，不表示当前任务实时状态。

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
5. 交接前优先更新 `state.json.lastAction`、当前步骤状态和验证证据。
6. 如果发现当前任务状态与文档不一致，先修正文档和 `state.json`，再继续执行。

## 可直接使用的脚本

```bash
bash scripts/init-workflow.sh
bash scripts/specflow.sh new "任务标题"
bash scripts/status.sh
bash scripts/next-step.sh
bash scripts/verify.sh
```

`agents/openai.yaml` 仅提供极简元信息；真正的入口仍然是本文件和仓库中的规则、模板、提示词与脚本。
