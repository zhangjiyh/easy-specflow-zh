# Codex 使用说明

Codex 使用这个项目时，优先把它当作一套统一规则，而不是平台专属扩展。

## 建议读取顺序

1. `SKILL.md`
2. `README.md`
3. `rules/workflow.md`
4. `rules/stage-transition.md`
5. `templates/`
6. `prompts/`

如果目标项目已经存在 `.specflow/`，再继续读取：

1. `.specflow/index.json`
2. 当前任务的 `state.json`
3. 当前任务的六份中文文档

## 如何配合 `.specflow/` 工作

Codex 的主要动作应该是：

1. 根据当前阶段补全对应文档。
2. 在推进任务时同步更新 `state.json`。
3. 通过 `scripts/` 查看状态、读取当前执行建议和做基础校验。
4. 与其他 agent 共享同一份任务目录，而不是额外生成一套私有记录。

推荐分工：

1. 在 `spec` 阶段补全 `任务说明.md`。
2. 在 `repo-map` 阶段补全 `代码库地图.md`。
3. 在 `plan` 阶段补全 `执行计划.md`，确保每步都有验证方式。
4. 在 `execute` 阶段把实际改动和验证结果写入 `进度记录.md`。
5. 在 `verify` 阶段汇总 `验证记录.md`，不要只写“已验证”。

## 建议使用的脚本

```bash
bash scripts/init-workflow.sh
bash scripts/specflow.sh new "任务标题"
bash scripts/status.sh
bash scripts/next-step.sh
bash scripts/verify.sh
```

如果 Codex 在技能目录中读取本仓库，而真正的工作项目在别处，可以让 shell 位于目标项目根目录，或显式设置 `SPECFLOW_ROOT`。

## `agents/openai.yaml` 的角色

本仓库保留了一个极简的 `agents/openai.yaml`，作用只有两个：

1. 帮助 Codex 识别这是一个可读的工作流仓库。
2. 提供简短展示名称和说明。

它不是工作流核心，也不承载复杂配置。真正的核心入口仍然是 `SKILL.md` 和仓库正文。
