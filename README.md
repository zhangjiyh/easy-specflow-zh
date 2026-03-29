# easy-specflow-zh

这是一个面向 AI 编码客户端的中文长任务工作流项目。

它提供统一的规则、模板、提示词、脚本和状态目录，让 Codex、Claude Code、OpenCode 等工具在同一个项目里按同一套方式推进任务：

`spec -> plan -> execute -> verify -> accept`

## 这是什么

`easy-specflow-zh` 解决的是中长任务推进混乱的问题。

当任务跨多个文件、多个模块、多个 agent 时，如果只靠聊天上下文，很容易出现这些情况：

1. 需求范围没写清楚就开始改。
2. 计划没有真实约束执行。
3. 验证和验收没有沉淀到文件。
4. 多个 agent 各写各的，状态不一致。

这个项目把任务统一落到 `<project-root>/.specflow/`，让文档、状态和脚本都围绕同一套目录工作。

## 适合什么场景

适合以下任务：

1. 需要持续几小时到几天推进的研发任务。
2. 会影响多个文件、多个模块或前后端联动的任务。
3. 需要分步验证和留痕的任务。
4. 希望多个 agent 共用同一份任务状态和文档的团队。

## 核心工作流

1. `spec`：写清目标、范围、约束和验收标准，对应 `任务说明.md`
2. `plan`：拆出可执行步骤和验证方式，对应 `执行计划.md`
3. `execute`：按计划逐步实现并记录，对应 `进度记录.md`
4. `verify`：对照需求和计划检查结果，对应 `进度记录.md` 中的验证结论
5. `accept`：形成最终验收结论，对应 `验收记录.md`

## 关键约束

这套 workflow 不是“把五份文档一次性补齐”。

默认要求：

1. 一次只推进一个阶段，或 `execute` 中的一个明确步骤。
2. `执行计划.md` 的步骤完成后必须勾选。
3. 只要还有未勾选步骤，就不能进入 `verify` 或 `accept`。
4. 只要还有阻塞、待补验证或“有条件通过”，就不能把 `status` 写成 `done`。

## 你会得到什么

仓库提供这些内容：

1. `SKILL.md`：skill 主入口
2. `rules/`：工作流规则、阶段切换规则、命名规范
3. `templates/`：中文任务模板
4. `prompts/`：五阶段提示词
5. `scripts/`：初始化、状态查看、下一步建议、基础校验
6. `schema/task-state.json`：`state.json` 结构说明

## 快速开始

如果你把这个仓库直接放在目标项目根目录：

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

默认结构：

```text
.specflow/
├─ index.json
├─ archive/
├─ trash/
└─ tasks/
   └─ TYYYYMMDD-001-任务标题/
      ├─ 任务说明.md
      ├─ 执行计划.md
      ├─ 进度记录.md
      ├─ 验收记录.md
      └─ state.json
```

说明：

1. 任务目录格式固定为 `TYYYYMMDD-序号-任务标题`
2. 文档名默认中文
3. `state.json` 是任务当前阶段和状态的事实来源
4. `index.json` 记录 `activeTaskId` 和任务索引摘要

## 常用命令

```bash
# 初始化
bash scripts/init-workflow.sh

# 新建任务
bash scripts/specflow.sh new "任务标题"

# 查看状态
bash scripts/status.sh

# 查看下一步建议
bash scripts/next-step.sh

# 基础校验
bash scripts/verify.sh

# 切换任务
bash scripts/specflow.sh switch T20260329-001

# 推进阶段
bash scripts/specflow.sh stage plan
bash scripts/specflow.sh stage execute
bash scripts/specflow.sh stage verify
bash scripts/specflow.sh stage accept

# 完成 / 归档
bash scripts/specflow.sh complete
bash scripts/specflow.sh archive
```

## 与 Codex / Claude Code / OpenCode 的关系

这个项目不是 Codex 专用仓库。

它的设计是：

1. Codex 读取 `SKILL.md`、`rules/`、`templates/`、`prompts/`
2. Claude Code 读取同一套仓库内容
3. OpenCode 读取同一套仓库内容
4. 多个 agent 共用同一个 `.specflow/`，而不是各维护一套私有目录

## 项目结构

```text
easy-specflow-zh/
├─ README.md
├─ CHANGELOG.md
├─ LICENSE
├─ SKILL.md
├─ docs/
├─ templates/
├─ prompts/
├─ rules/
├─ schema/
├─ scripts/
├─ agents/
└─ examples/
```

## 文档导航

1. 使用流程：`docs/usage-cycle-zh.md`
2. Codex 使用说明：`docs/codex.md`
3. Claude Code 使用说明：`docs/claude-code.md`
4. OpenCode 使用说明：`docs/opencode.md`
5. 跨 agent 协作：`docs/cross-agent-collaboration.md`
6. 示例：`examples/vue-spring/README.md`
