# OpenCode 使用说明

OpenCode 可以直接使用这个项目，不需要单独维护一套平台专属结构。

## 建议读取顺序

1. `README.md`
2. `rules/workflow.md`
3. `rules/stage-transition.md`
4. `templates/`
5. `prompts/`

如果任务已经开始，再读取：

1. `.specflow/index.json`
2. 当前任务目录中的 `state.json`
3. 当前任务文档

## 建议使用方式

OpenCode 更适合在统一规则下执行明确任务，因此推荐：

1. 先从 `state.json` 判断当前阶段。
2. 再从 `执行计划.md` 中读取当前步骤。
3. 执行后把改动和验证摘要写入 `进度记录.md`。
4. 完成后更新 `state.json` 的阶段、时间和最近操作摘要。

## 与其他 agent 协作的方法

1. 不复制任务目录。
2. 不额外引入 `opencode/` 之类的私有子目录。
3. 只使用同一份 `.specflow/` 作为任务事实来源。
4. 如果发现文档与实现不一致，先补齐记录，再继续推进。

## 推荐辅助脚本

```bash
bash scripts/status.sh
bash scripts/next-step.sh
bash scripts/verify.sh
```

这些脚本不会依赖 OpenCode 私有能力，任何终端都可以直接使用。
