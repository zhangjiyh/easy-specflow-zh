# easy-specflow-zh

`easy-specflow-zh` 是一套面向复杂任务、人机协作、多 Agent 场景的中文长任务执行协议。

它不是模板集、prompt 包，也不是某个平台的专属适配层。它解决的是任务治理问题：让任务按正确顺序、正确边界、带验证证据地稳定推进，并在最终验收时仍然可回溯。

协议主流程：

`spec -> repo-map -> plan -> execute -> verify -> accept`

中文对应：

`需求定义 -> 代码库定位 -> 执行计划 -> 执行实现 -> 验证汇总 -> 验收结论`

适用对象包括 Codex、Claude Code、OpenCode，也适合人工协作或多人接力场景。

## 这个协议解决什么问题

中长研发任务一旦跨文件、跨模块、跨多人，最容易出现的不是“不会写代码”，而是流程失真：

1. 需求不清就开工。
2. 文件范围没找准就写计划。
3. 计划写了，但没有真正约束执行。
4. 执行做了，但没有留下验证证据。
5. 多 Agent / 多人协作时，状态在聊天和文件之间漂移。
6. 最终验收缺少前序依据，只能给主观结论。

`easy-specflow-zh` 的目标不是让人或模型更快乱动手，而是把任务统一收敛到 `<project-root>/.specflow/`，让文档、状态和脚本围绕同一套协议推进。

## 核心价值

这套协议强调四件事：

1. 先写清任务目标与边界，再推进实现。
2. 先做代码库定位，再写执行计划。
3. 计划、执行、验证、验收之间要有明确映射关系。
4. 验证必须证据化，验收必须基于前序证据。

它的核心竞争力不是“帮你生成更多文本”，而是“帮你减少猜测、减少越界、减少误判完成”。

## 六阶段协议

### `spec -> repo-map -> plan -> execute -> verify -> accept`
### （需求定义 → 代码库定位 → 执行计划 → 执行实现 → 验证汇总 → 验收结论）

各阶段职责不是并列的模板说明，而是有依赖关系的推进链路：

1. `spec`
   明确目标、范围、约束、非目标和验收标准，对应 `任务说明.md`。
2. `repo-map`
   在计划前确认真实代码上下文，识别关键目录、入口文件、直接相关文件、潜在影响面和搜索路径，对应 `代码库地图.md`。
3. `plan`
   基于 `spec` 与 `repo-map` 拆分步骤，并为每一步写清修改范围、执行动作、验证方式、完成标准和当前状态，对应 `执行计划.md`。
4. `execute`
   按计划连续执行剩余步骤，默认从 Step 1 推进到 Step N，直到全部已承诺步骤完成或遇到阻塞；把每一步的改动、影响文件、验证命令、验证结果和阻塞写入 `进度记录.md`。
5. `verify`
   对执行记录进行结构化证据汇总，检查需求、代码边界、计划步骤和实际结果是否一致，对应 `验证记录.md`。
6. `accept`
   基于 `任务说明.md`、`代码库地图.md`、`执行计划.md`、`进度记录.md`、`验证记录.md` 给出最终验收结论与遗留说明，对应 `验收记录.md`。

依赖关系很明确：

1. 没有 `spec`，就没有明确目标与验收标准。
2. 没有 `repo-map`，`plan` 容易建立在猜测上。
3. 没有带验证方式的 `plan`，`execute` 就缺少约束。
4. 没有执行记录与验证证据，`verify` 和 `accept` 就会失去依据。

## 为什么需要 `repo-map`

`spec -> plan` 之间增加 `repo-map`，不是为了多一份文档，而是为了把“代码边界共识”变成正式阶段：

1. 没有 `repo-map` 时，计划容易建立在猜测上，特别是在复杂代码库中。
2. 对跨模块任务，先识别关键目录、入口文件和潜在影响面，是计划可执行的前提。
3. `repo-map` 能帮助 review 判断本次修改是否越界。
4. 多 Agent / 多人协作时，`repo-map` 是共享“改动边界共识”的最低成本方式。

如果任务很小，`repo-map` 可以写得很轻；但对复杂任务，它不应该被省略成一句“先搜一下相关文件”。

## 为什么验证必须证据化

仅仅写“已验证”不够，因为那只是结论，不是依据。

在这套协议里，`verify` 是验证证据层，至少应能回答两个问题：

1. 做了什么验证？
2. 为什么认为这一步真的通过了？

因此验证记录至少要能承载：

1. 验证命令
2. 验证范围
3. 预期结果
4. 实际结果
5. 是否通过
6. 失败摘要
7. 遗留风险或待补验证项

验证证据的价值在于：

1. 降低“误判完成”的风险。
2. 为后续 `accept` 提供依据。
3. 支撑多人协作时的共同判断。
4. 让回溯不依赖聊天上下文。

## 特别适合哪些任务

这套协议特别适合：

1. 中长研发任务
2. 跨文件改动
3. 多模块协作
4. 多 Agent 协作
5. 需要回溯与验收的任务
6. 容易因上下文漂移而跑偏的开发任务

它不是为了取代 IDE 增强、代码补全或单次命令执行工具，而是为了提供一层轻量的任务治理协议。

## 使用原则

1. 一次只推进一个明确阶段；进入 `execute` 后，默认连续推进剩余步骤，直到完成全部计划或遇到阻塞。
2. `repo-map` 是正式阶段，不是 README 里的可选建议。
3. `执行计划.md` 中的每一步都必须先写清验证方式，才算计划完成。
4. `execute` 阶段每完成一个步骤都必须同步更新计划状态和执行记录，但默认不要因为单步完成就中断整轮执行。
5. 对用户默认在全部计划步骤完成后统一总结；只有遇到阻塞、高风险决策、权限不足或用户明确要求逐步确认时，才中途停下来。
6. `verify` 不能凭空新增事实，只能汇总前面步骤留下的执行与验证证据。
7. `accept` 不是主观收尾，而是对前序证据做最终结论。
8. 只要仍有阻塞、待补验证或“有条件通过”，就不能把 `status` 标记为 `done`。

## 快速开始

如果仓库就在目标项目根目录：

```bash
bash scripts/init-workflow.sh
bash scripts/specflow.sh new "任务标题"
bash scripts/status.sh
```

如果仓库和目标项目分开：

```bash
cd /path/to/your-project
bash /path/to/easy-specflow-zh/scripts/init-workflow.sh
bash /path/to/easy-specflow-zh/scripts/specflow.sh new "任务标题"
bash /path/to/easy-specflow-zh/scripts/next-step.sh
```

也可以显式指定工作目录：

```bash
SPECFLOW_ROOT=/path/to/your-project bash /path/to/easy-specflow-zh/scripts/specflow.sh status
```

## `.specflow/` 目录

默认任务工作目录：

```text
<project-root>/.specflow/
```

协议目标结构：

```text
.specflow/
├─ index.json
├─ archive/
├─ trash/
└─ tasks/
   └─ TYYYYMMDD-001-任务标题/
      ├─ 任务说明.md
      ├─ 代码库地图.md
      ├─ 执行计划.md
      ├─ 进度记录.md
      ├─ 验证记录.md
      ├─ 验收记录.md
      └─ state.json
```

说明：

1. 任务目录格式固定为 `TYYYYMMDD-序号-任务标题`
2. 文档名默认中文
3. `state.json` 是任务当前阶段和状态的事实来源
4. `index.json` 记录当前激活任务 ID 和任务索引摘要

## 常用命令

```bash
# 初始化
bash scripts/init-workflow.sh

# 新建任务
bash scripts/specflow.sh new "任务标题"

# 查看状态
bash scripts/status.sh

# 查看当前执行建议
bash scripts/next-step.sh

# 流程一致性检查
bash scripts/verify.sh

# 切换任务
bash scripts/specflow.sh switch T20260329-001

# 推进阶段
bash scripts/specflow.sh stage repo-map   # 代码库定位
bash scripts/specflow.sh stage plan       # 执行计划
bash scripts/specflow.sh stage execute    # 执行实现
bash scripts/specflow.sh stage verify     # 验证汇总
bash scripts/specflow.sh stage accept     # 验收结论

# 满足完成条件后标记 done
bash scripts/specflow.sh complete

# 归档
bash scripts/specflow.sh archive
```

## 仓库内容

1. `SKILL.md`：skill 主入口
2. `rules/`：工作流规则、阶段切换规则、命名规范
3. `templates/`：中文任务模板
4. `prompts/`：六阶段提示词
5. `scripts/`：初始化、状态查看、下一步建议、流程一致性检查
6. `schema/task-state.json`：`state.json` 结构说明

## 与不同工具的关系

这个项目不是某个平台的专用适配层。

它的目标是让不同工具读取同一套仓库内容，并共同使用同一个 `.specflow/`：

1. Codex 读取 `SKILL.md`、`rules/`、`templates/`、`prompts/`
2. Claude Code 读取同一套规则、模板和状态目录
3. OpenCode 读取同一套规则、模板和状态目录
4. 人工协作者以同一套文档和状态文件作为共享事实来源

## 多 Agent / 人工协作

在多 Agent / 多人场景里，这套协议依赖三样东西保持一致：

1. 同一个任务目录
2. 同一份 `state.json`
3. 同一套计划、执行、验证与验收证据

因此它适合这样的协作分工：

1. 一个 Agent 负责 `spec / repo-map / plan`（需求定义 / 代码库定位 / 执行计划）
2. 另一个 Agent 负责 `execute / verify`（执行实现 / 验证汇总）
3. 人工 reviewer 负责 `accept`（验收结论）

只要共享文件持续更新，协作就不依赖单次对话上下文。

## 文档导航

1. 使用流程：`docs/usage-cycle-zh.md`
2. Codex 使用说明：`docs/codex.md`
3. Claude Code 使用说明：`docs/claude-code.md`
4. OpenCode 使用说明：`docs/opencode.md`
5. 跨 agent 协作：`docs/cross-agent-collaboration.md`
6. 示例：`examples/vue-spring/README.md`

## 版权与许可

Copyright (c) 2026 zhangji

本仓库采用 MIT License 发布，详见 `LICENSE` 和 `COPYRIGHT`。
