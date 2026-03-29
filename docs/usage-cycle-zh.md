# 使用流程说明

这份说明描述一个典型的使用周期，帮助团队把任务稳定推进到 `.specflow/` 中。

## 1. 初始化 `.specflow/`

在目标项目根目录执行：

```bash
bash scripts/init-workflow.sh
```

如果脚本仓库和目标项目分离，请先切换到目标项目根目录，再调用脚本绝对路径。

初始化后会得到：

```text
.specflow/
├─ index.json
├─ archive/
├─ trash/
└─ tasks/
```

## 2. 新建任务

```bash
bash scripts/specflow.sh new "登录与鉴权重构"
```

系统会创建：

```text
.specflow/tasks/TYYYYMMDD-001-登录与鉴权重构/
├─ 任务说明.md
├─ 执行计划.md
├─ 进度记录.md
├─ 验收记录.md
└─ state.json
```

## 3. 编写任务说明

首先完成 `任务说明.md`，至少写清：

1. 任务背景和目标。
2. 范围与非目标。
3. 约束和禁改项。
4. 验收标准。

完成后，可以把 `state.json.stage` 保持在 `spec`，直到关键信息足够进入计划阶段。

## 4. 制定执行计划

当目标和边界清楚后，补全 `执行计划.md`：

1. 拆出阶段内步骤。
2. 标明每一步的目标、影响范围、验证方式和回滚思路。
3. 使用统一的步骤勾选格式，便于 `next-step.sh` 给出建议。

计划确认后，把 `state.json.stage` 更新到 `plan`。

## 5. 执行与记录

进入执行阶段后：

1. 每次只处理一个明确步骤。
2. 改动摘要、验证摘要、问题和阻塞都写入 `进度记录.md`。
3. 当计划中某一步完成时，记得在 `执行计划.md` 勾选对应项。

执行中可随时查看：

```bash
bash scripts/status.sh
bash scripts/next-step.sh
```

## 6. 验证

所有关键步骤完成后，进入 `verify`：

1. 对照 `任务说明.md` 的验收标准逐项检查。
2. 对照 `执行计划.md` 检查是否存在未完成项。
3. 把验证过程和结论补充到 `进度记录.md` 的验证部分。

基础校验可用：

```bash
bash scripts/verify.sh
```

## 7. 验收

验证通过后，整理 `验收记录.md`：

1. 总结交付内容。
2. 记录验证结论。
3. 说明遗留问题和后续建议。

验收结论明确后，可将 `state.json.status` 更新为 `done`，并在需要时归档任务。

## 8. 归档或恢复

常用命令：

```bash
bash scripts/specflow.sh archive
bash scripts/specflow.sh restore T20260329-001
bash scripts/specflow.sh delete
```

建议：

1. 已完成且暂不继续推进的任务归档到 `archive/`。
2. 暂时废弃但可能恢复的任务移到 `trash/`。
3. 所有归档和恢复动作都同步更新 `index.json` 和 `state.json`。
