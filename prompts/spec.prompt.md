# spec 阶段提示词

## 目标

澄清当前任务的目标、范围、限制和验收标准。

## 输入

1. `README.md`
2. `rules/workflow.md`
3. `rules/stage-transition.md`
4. 当前任务目录中的 `state.json`
5. 当前任务目录中的 `任务说明.md`

## 输出

1. 补全或重写 `任务说明.md`
2. 更新 `state.json.updatedAt`
3. 更新 `state.json.lastAction`

## 要求

1. 使用中文。
2. 不扩展无关需求。
3. 不确定事项要写成待确认项。
4. 阶段仍保持为 `spec`，直到进入计划条件满足。
5. 不要在 `spec` 阶段提前生成 `execute / verify / accept` 的完成结论。
