# easy-specflow-zh

`easy-specflow-zh` 是一套中文长任务工作流约定。

它用统一的目录、模板、脚本和状态文件，把中长研发任务固定到同一条推进链路里：

`spec -> plan -> execute -> verify -> accept`

适用对象包括 Codex、Claude Code、OpenCode，也适合人工协作场景。

## 简介

中长任务一旦跨文件、跨模块、跨多人，最容易出的问题通常是：

1. 需求没有写清楚就开始改。
2. 计划只是写了，没有真正约束执行。
3. 验证和验收没有留痕。
4. 不同工具或不同人维护了不同版本的任务状态。

这个仓库的做法很直接：把任务统一放到 `<project-root>/.specflow/`，让文档、状态和脚本都围绕同一套目录工作。

## 核心流程

1. `spec`：明确目标、范围、约束和验收标准，对应 `任务说明.md`
2. `plan`：拆分步骤、约定验证方式，对应 `执行计划.md`
3. `execute`：按计划推进实现并记录结果，对应 `进度记录.md`
4. `verify`：对照需求和计划检查结果，对应 `进度记录.md` 中的验证结论
5. `accept`：形成验收结论和遗留说明，对应 `验收记录.md`

## 使用原则

1. 一次只推进一个阶段，或 `execute` 中的一个明确步骤。
2. `执行计划.md` 中的步骤完成后必须立即勾选。
3. 只要还有未勾选步骤，就不能进入 `verify` 或 `accept`。
4. 只要还有阻塞、待补验证或“有条件通过”，就不能把 `status` 写成 `done`。

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

# 满足完成条件后标记 done
bash scripts/specflow.sh complete

# 归档
bash scripts/specflow.sh archive
```

## 仓库内容

1. `SKILL.md`：skill 主入口
2. `rules/`：工作流规则、阶段切换规则、命名规范
3. `templates/`：中文任务模板
4. `prompts/`：五阶段提示词
5. `scripts/`：初始化、状态查看、下一步建议、基础校验
6. `schema/task-state.json`：`state.json` 结构说明

## 与不同工具的关系

这个项目不是某个平台的专用适配层。

它的目标是让不同工具读取同一套仓库内容，并共同使用同一个 `.specflow/`：

1. Codex 读取 `SKILL.md`、`rules/`、`templates/`、`prompts/`
2. Claude Code 读取同一套规则、模板和状态目录
3. OpenCode 读取同一套规则、模板和状态目录

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
