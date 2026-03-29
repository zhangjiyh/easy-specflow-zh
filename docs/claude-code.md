# Claude Code 使用说明

Claude Code 使用这个项目时，不需要额外适配层，直接读取统一结构即可。

## 推荐读取内容

1. `README.md`
2. `rules/workflow.md`
3. `rules/stage-transition.md`
4. `templates/`
5. `prompts/`

如果项目中已经存在任务，再读取：

1. `.specflow/index.json`
2. 当前任务目录的 `state.json`
3. 任务文档

## 推荐工作方式

1. 在 `spec` 阶段补全 `任务说明.md`。
2. 在 `plan` 阶段补全 `执行计划.md`。
3. 在 `execute` 阶段把代码改动摘要和验证摘要写入 `进度记录.md`。
4. 在 `verify` 和 `accept` 阶段继续使用同一套文档，不再生成新的平台私有文件。

## 与其他 agent 协作

Claude Code 与 Codex、OpenCode 协作时，重点是共享状态：

1. 共同使用 `.specflow/`。
2. 共同更新同一个 `state.json`。
3. 共同维护同一套中文文档。
4. 发生分歧时，以仓库中的规则、计划和状态为准。

## 建议

如果 Claude Code 完成了 `spec` 或 `plan`，最好顺手更新：

1. `state.json.stage`
2. `state.json.updatedAt`
3. `state.json.lastAction`

这样下一个 agent 接手时不需要再猜测当前进度。
