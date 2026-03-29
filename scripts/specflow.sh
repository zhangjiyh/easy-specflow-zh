#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="${SPECFLOW_ROOT:-$(pwd)}"
BASE_DIR="$PROJECT_ROOT/.specflow"
TASKS_DIR="$BASE_DIR/tasks"
ARCHIVE_DIR="$BASE_DIR/archive"
TRASH_DIR="$BASE_DIR/trash"
INDEX_FILE="$BASE_DIR/index.json"
DEFAULT_LANGUAGE="zh-CN"

now() {
  date '+%Y-%m-%dT%H:%M:%S%z' | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/'
}

log() {
  echo "[specflow] $*"
}

error() {
  echo "[specflow] $*" >&2
  exit 1
}

sanitize_inline() {
  printf '%s' "$*" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

path_labelify() {
  local input
  input="$(sanitize_inline "$*")"
  input="$(printf '%s' "$input" | sed -E 's#[][(){}<>:"/\\|?*]#-#g; s/[[:space:]]+/-/g; s/-+/-/g; s/^-+//; s/-+$//')"
  [[ -n "$input" ]] || input="task"
  printf '%s' "$input"
}

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

json_get_scalar() {
  local file="$1"
  local key="$2"
  sed -n -E 's/^[[:space:]]*"'$key'":[[:space:]]*"([^"]*)".*$/\1/p' "$file" | head -n 1
}

project_rel() {
  local path="$1"
  path="${path#$PROJECT_ROOT/}"
  printf '%s' "$path"
}

doc_filename() {
  case "$1" in
    spec) printf '任务说明.md' ;;
    repo-map) printf '代码库地图.md' ;;
    plan) printf '执行计划.md' ;;
    execute) printf '进度记录.md' ;;
    verify) printf '验证记录.md' ;;
    accept) printf '验收记录.md' ;;
    *) error "未知文档类型: $1" ;;
  esac
}

template_file_path() {
  printf '%s/templates/%s' "$REPO_ROOT" "$(doc_filename "$1")"
}

task_doc_path() {
  local dir="$1"
  local kind="$2"
  printf '%s/%s' "$dir" "$(doc_filename "$kind")"
}

require_init() {
  [[ -d "$BASE_DIR" && -f "$INDEX_FILE" ]] || error "未初始化。先执行: bash scripts/init-workflow.sh"
}

current_active_task_id() {
  [[ -f "$INDEX_FILE" ]] || return 0
  sed -n -E 's/^[[:space:]]*"activeTaskId":[[:space:]]*"([^"]+)".*$/\1/p' "$INDEX_FILE" | head -n 1
}

require_active_task_id() {
  local id
  id="$(current_active_task_id)"
  [[ -n "$id" ]] || error "当前没有 activeTaskId。先执行: specflow.sh new \"任务标题\" 或 specflow.sh switch <TASK_ID>"
  printf '%s' "$id"
}

find_task_dir_in_bucket() {
  local bucket="$1"
  local id="$2"
  local dir
  for dir in "$bucket"/"$id"-*; do
    if [[ -d "$dir" ]]; then
      printf '%s' "$dir"
      return 0
    fi
  done
  return 1
}

find_task_dir() {
  local id="$1"
  local dir
  dir="$(find_task_dir_in_bucket "$TASKS_DIR" "$id" || true)"
  [[ -n "$dir" ]] && { printf '%s' "$dir"; return 0; }
  dir="$(find_task_dir_in_bucket "$ARCHIVE_DIR" "$id" || true)"
  [[ -n "$dir" ]] && { printf '%s' "$dir"; return 0; }
  dir="$(find_task_dir_in_bucket "$TRASH_DIR" "$id" || true)"
  [[ -n "$dir" ]] && { printf '%s' "$dir"; return 0; }
  return 1
}

load_state() {
  STATE_FILE="$1"
  STATE_ID="$(json_get_scalar "$STATE_FILE" "id")"
  STATE_TITLE="$(json_get_scalar "$STATE_FILE" "title")"
  STATE_STAGE="$(json_get_scalar "$STATE_FILE" "stage")"
  STATE_STATUS="$(json_get_scalar "$STATE_FILE" "status")"
  STATE_LANGUAGE="$(json_get_scalar "$STATE_FILE" "language")"
  STATE_CREATED_AT="$(json_get_scalar "$STATE_FILE" "createdAt")"
  STATE_UPDATED_AT="$(json_get_scalar "$STATE_FILE" "updatedAt")"
  STATE_LAST_AGENT="$(json_get_scalar "$STATE_FILE" "agent")"
  STATE_LAST_SUMMARY="$(json_get_scalar "$STATE_FILE" "summary")"
  STATE_LAST_AT="$(json_get_scalar "$STATE_FILE" "at")"
}

write_state() {
  local file="$1"
  cat > "$file" <<EOF
{
  "id": "$(json_escape "$STATE_ID")",
  "title": "$(json_escape "$STATE_TITLE")",
  "stage": "$(json_escape "$STATE_STAGE")",
  "status": "$(json_escape "$STATE_STATUS")",
  "language": "$(json_escape "$STATE_LANGUAGE")",
  "createdAt": "$(json_escape "$STATE_CREATED_AT")",
  "updatedAt": "$(json_escape "$STATE_UPDATED_AT")",
  "artifacts": {
    "spec": "任务说明.md",
    "repoMap": "代码库地图.md",
    "plan": "执行计划.md",
    "execute": "进度记录.md",
    "verify": "验证记录.md",
    "accept": "验收记录.md"
  },
  "lastAction": {
    "agent": "$(json_escape "$STATE_LAST_AGENT")",
    "summary": "$(json_escape "$STATE_LAST_SUMMARY")",
    "at": "$(json_escape "$STATE_LAST_AT")"
  }
}
EOF
}

copy_templates() {
  local target_dir="$1"
  cp "$REPO_ROOT/templates/任务说明.md" "$target_dir/任务说明.md"
  cp "$REPO_ROOT/templates/代码库地图.md" "$target_dir/代码库地图.md"
  cp "$REPO_ROOT/templates/执行计划.md" "$target_dir/执行计划.md"
  cp "$REPO_ROOT/templates/进度记录.md" "$target_dir/进度记录.md"
  cp "$REPO_ROOT/templates/验证记录.md" "$target_dir/验证记录.md"
  cp "$REPO_ROOT/templates/验收记录.md" "$target_dir/验收记录.md"
}

next_id() {
  local day max seq base dir
  day="$(date '+%Y%m%d')"
  max=0

  for dir in "$TASKS_DIR"/T"$day"-* "$ARCHIVE_DIR"/T"$day"-* "$TRASH_DIR"/T"$day"-*; do
    [[ -d "$dir" ]] || continue
    base="$(basename "$dir")"
    seq="$(printf '%s' "$base" | sed -E 's/^T[0-9]{8}-([0-9]{3}).*$/\1/')"
    if [[ "$seq" =~ ^[0-9]{3}$ ]] && (( 10#$seq > max )); then
      max=$((10#$seq))
    fi
  done

  printf 'T%s-%03d' "$day" "$((max + 1))"
}

write_bucket_json() {
  local bucket_dir="$1"
  local first=1
  local task_dir

  printf '['
  if [[ -d "$bucket_dir" ]]; then
    while IFS= read -r task_dir; do
      [[ -f "$task_dir/state.json" ]] || continue
      load_state "$task_dir/state.json"
      if [[ "$first" -eq 0 ]]; then
        printf ','
      fi
      printf '\n    {'
      printf '\n      "id": "%s",' "$(json_escape "$STATE_ID")"
      printf '\n      "title": "%s",' "$(json_escape "$STATE_TITLE")"
      printf '\n      "stage": "%s",' "$(json_escape "$STATE_STAGE")"
      printf '\n      "status": "%s",' "$(json_escape "$STATE_STATUS")"
      printf '\n      "updatedAt": "%s",' "$(json_escape "$STATE_UPDATED_AT")"
      printf '\n      "path": "%s"' "$(json_escape "$(project_rel "$task_dir")")"
      printf '\n    }'
      first=0
    done < <(find "$bucket_dir" -mindepth 1 -maxdepth 1 -type d | sort)
  fi
  if [[ "$first" -eq 0 ]]; then
    printf '\n  '
  fi
  printf ']'
}

refresh_index() {
  local active_id="${1:-$(current_active_task_id)}"
  local active_dir

  if [[ -n "$active_id" ]]; then
    active_dir="$(find_task_dir_in_bucket "$TASKS_DIR" "$active_id" || true)"
    [[ -n "$active_dir" ]] || active_id=""
  fi

  mkdir -p "$BASE_DIR"
  {
    printf '{\n'
    printf '  "version": 1,\n'
    printf '  "language": "%s",\n' "$DEFAULT_LANGUAGE"
    if [[ -n "$active_id" ]]; then
      printf '  "activeTaskId": "%s",\n' "$(json_escape "$active_id")"
    else
      printf '  "activeTaskId": null,\n'
    fi
    printf '  "updatedAt": "%s",\n' "$(json_escape "$(now)")"
    printf '  "tasks": '
    write_bucket_json "$TASKS_DIR"
    printf ',\n  "archive": '
    write_bucket_json "$ARCHIVE_DIR"
    printf ',\n  "trash": '
    write_bucket_json "$TRASH_DIR"
    printf '\n}\n'
  } > "$INDEX_FILE"
}

print_bucket() {
  local title="$1"
  local bucket_dir="$2"
  local active_id
  local task_dir
  local found=0

  active_id="$(current_active_task_id)"
  echo "## $title"

  if [[ -d "$bucket_dir" ]]; then
    while IFS= read -r task_dir; do
      [[ -f "$task_dir/state.json" ]] || continue
      load_state "$task_dir/state.json"
      if [[ "$STATE_ID" == "$active_id" ]]; then
        printf -- '* %s | %s | %s | %s\n' "$STATE_ID" "$STATE_STAGE" "$STATE_STATUS" "$STATE_TITLE"
      else
        printf -- '- %s | %s | %s | %s\n' "$STATE_ID" "$STATE_STAGE" "$STATE_STATUS" "$STATE_TITLE"
      fi
      found=1
    done < <(find "$bucket_dir" -mindepth 1 -maxdepth 1 -type d | sort)
  fi

  if [[ "$found" -eq 0 ]]; then
    echo "- (空)"
  fi
  echo
}

next_plan_item() {
  local plan_file="$1"
  [[ -f "$plan_file" ]] || return 0
  sed -n -E 's/^- \[ \] (.*)$/\1/p' "$plan_file" | head -n 1
}

is_default_template() {
  local file="$1"
  local kind="$2"
  [[ -f "$file" ]] || return 1
  cmp -s "$file" "$(template_file_path "$kind")"
}

first_empty_step_field() {
  local file="$1"
  local field="$2"
  [[ -f "$file" ]] || return 0
  awk -v field="$field" '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }
    function emit_if_missing() {
      if (waiting == 1 && has_detail == 0) {
        reported = 1
        print (step != "" ? step : "步骤") " 缺少" field
        exit
      }
      waiting = 0
      has_detail = 0
    }
    /^### Step / {
      emit_if_missing()
      step=$0
    }
    {
      prefix = "- " field "："
      if (index($0, prefix) == 1) {
        emit_if_missing()
        value = trim(substr($0, length(prefix) + 1))
        if (value == "" || value ~ /^待开始 \/ 进行中 \/ 已完成 \/ 阻塞$/) {
          waiting = 1
          next
        }
        has_detail = 1
        next
      }
      if (waiting == 1) {
        line = trim($0)
        if (line == "") {
          next
        }
        if ($0 ~ /^- [^：]+：/ || $0 ~ /^### Step /) {
          emit_if_missing()
        } else {
          has_detail = 1
        }
      }
    }
    END {
      if (reported != 1 && waiting == 1 && has_detail == 0) {
        print (step != "" ? step : "步骤") " 缺少" field
      }
    }
  ' "$file"
}

first_empty_progress_field() {
  local file="$1"
  local field="$2"
  [[ -f "$file" ]] || return 0
  awk -v field="$field" '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }
    function emit_if_missing() {
      if (waiting == 1 && has_detail == 0) {
        reported = 1
        print (record != "" ? record : "记录") " 缺少" field
        exit
      }
      waiting = 0
      has_detail = 0
    }
    /^### 记录 / {
      emit_if_missing()
      record=$0
    }
    {
      prefix = "- " field "："
      if (index($0, prefix) == 1) {
        emit_if_missing()
        value = trim(substr($0, length(prefix) + 1))
        if (value == "" || value ~ /^是 \/ 否 \/ 待补验证$/) {
          waiting = 1
          next
        }
        has_detail = 1
        next
      }
      if (waiting == 1) {
        line = trim($0)
        if (line == "") {
          next
        }
        if ($0 ~ /^- [^：]+：/ || $0 ~ /^### 记录 /) {
          emit_if_missing()
        } else {
          has_detail = 1
        }
      }
    }
    END {
      if (reported != 1 && waiting == 1 && has_detail == 0) {
        print (record != "" ? record : "记录") " 缺少" field
      }
    }
  ' "$file"
}

first_non_clear_label_value() {
  local file="$1"
  local field="$2"
  [[ -f "$file" ]] || return 0
  awk -v field="$field" '
    {
      prefix = "- " field "："
      if (index($0, prefix) == 1) {
        value = substr($0, length(prefix) + 1)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        if (value != "" && value != "-" && value != "无" && value !~ /^无/ && value !~ /^暂无/ && value !~ /^暂未/ && value != "none" && value != "None" && value != "n/a" && value != "N/A") {
          print value
          exit
        }
      }
    }
  ' "$file"
}

first_unchecked_box() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  sed -n -E 's/^- \[ \] (.*)$/\1/p' "$file" | head -n 1
}

accept_conclusion() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  sed -n -E 's/^- 结论：[[:space:]]*(.*)$/\1/p' "$file" | head -n 1 | sed -E 's/[[:space:]]+$//'
}

verify_accept_readiness() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  sed -n -E 's/^- 是否满足进入 accept：[[:space:]]*(.*)$/\1/p' "$file" | head -n 1 | sed -E 's/[[:space:]]+$//'
}

progress_blocked_value() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  sed -n -E 's/^- BLOCKED：[[:space:]]*(.*)$/\1/p' "$file" | head -n 1 | sed -E 's/[[:space:]]+$//'
}

is_clear_value() {
  local value
  value="$(sanitize_inline "${1:-}")"
  case "$value" in
    ""|"-"|"无"|"none"|"None"|"n/a"|"N/A") return 0 ;;
    *) return 1 ;;
  esac
}

ensure_stage_requirements() {
  local target_stage="$1"
  local dir="$2"
  local spec_file repo_map_file plan_file execute_file verify_file
  local unresolved missing_field

  spec_file="$(task_doc_path "$dir" spec)"
  repo_map_file="$(task_doc_path "$dir" repo-map)"
  plan_file="$(task_doc_path "$dir" plan)"
  execute_file="$(task_doc_path "$dir" execute)"
  verify_file="$(task_doc_path "$dir" verify)"

  case "$target_stage" in
    repo-map)
      if is_default_template "$spec_file" spec; then
        error "任务说明.md 仍是默认模板，不能进入 repo-map"
      fi
      ;;
    plan)
      if is_default_template "$spec_file" spec; then
        error "任务说明.md 仍是默认模板，不能进入 plan"
      fi
      if is_default_template "$repo_map_file" repo-map; then
        error "代码库地图.md 仍是默认模板，不能进入 plan"
      fi
      ;;
    execute)
      if is_default_template "$plan_file" plan; then
        error "执行计划.md 仍是默认模板，不能进入 execute"
      fi
      if ! grep -qE '^- \[[ x]\] ' "$plan_file"; then
        error "执行计划.md 缺少步骤列表，不能进入 execute"
      fi
      missing_field="$(first_empty_step_field "$plan_file" "验证方式")"
      if [[ -n "$missing_field" ]]; then
        error "$missing_field，不能进入 execute"
      fi
      missing_field="$(first_empty_step_field "$plan_file" "完成标准")"
      if [[ -n "$missing_field" ]]; then
        error "$missing_field，不能进入 execute"
      fi
      ;;
    verify)
      unresolved="$(next_plan_item "$plan_file")"
      if [[ -n "$unresolved" ]]; then
        error "执行计划仍有未勾选步骤，不能进入 verify: $unresolved"
      fi
      if is_default_template "$execute_file" execute; then
        error "进度记录.md 仍是默认模板，不能进入 verify"
      fi
      missing_field="$(first_empty_progress_field "$execute_file" "验证结果")"
      if [[ -n "$missing_field" ]]; then
        error "$missing_field，不能进入 verify"
      fi
      missing_field="$(first_empty_progress_field "$execute_file" "是否通过")"
      if [[ -n "$missing_field" ]]; then
        error "$missing_field，不能进入 verify"
      fi
      ;;
    accept)
      unresolved="$(next_plan_item "$plan_file")"
      if [[ -n "$unresolved" ]]; then
        error "执行计划仍有未勾选步骤，不能进入 accept: $unresolved"
      fi
      if is_default_template "$execute_file" execute; then
        error "进度记录.md 仍是默认模板，不能进入 accept"
      fi
      if is_default_template "$verify_file" verify; then
        error "验证记录.md 仍是默认模板，不能进入 accept"
      fi
      ;;
  esac
}

done_guard_check() {
  local dir="$1"
  local spec_file repo_map_file plan_file execute_file verify_file accept_file
  local unresolved unchecked conclusion blocked pending failed readiness

  DONE_GUARD_FAILURES=0
  spec_file="$(task_doc_path "$dir" spec)"
  repo_map_file="$(task_doc_path "$dir" repo-map)"
  plan_file="$(task_doc_path "$dir" plan)"
  execute_file="$(task_doc_path "$dir" execute)"
  verify_file="$(task_doc_path "$dir" verify)"
  accept_file="$(task_doc_path "$dir" accept)"

  if is_default_template "$repo_map_file" repo-map; then
    echo "[失败] 代码库地图.md 仍是默认模板"
    DONE_GUARD_FAILURES=$((DONE_GUARD_FAILURES + 1))
  fi

  unresolved="$(next_plan_item "$plan_file")"
  if [[ -n "$unresolved" ]]; then
    echo "[失败] 执行计划仍有未勾选步骤: $unresolved"
    DONE_GUARD_FAILURES=$((DONE_GUARD_FAILURES + 1))
  fi

  unchecked="$(first_unchecked_box "$spec_file")"
  if [[ -n "$unchecked" ]]; then
    echo "[失败] 任务说明仍有未回填的验收标准: $unchecked"
    DONE_GUARD_FAILURES=$((DONE_GUARD_FAILURES + 1))
  fi

  unchecked="$(first_unchecked_box "$accept_file")"
  if [[ -n "$unchecked" ]]; then
    echo "[失败] 验收记录仍有未通过项: $unchecked"
    DONE_GUARD_FAILURES=$((DONE_GUARD_FAILURES + 1))
  fi

  blocked="$(progress_blocked_value "$execute_file")"
  if ! is_clear_value "$blocked"; then
    echo "[失败] 进度记录中的 BLOCKED 未清空: $blocked"
    DONE_GUARD_FAILURES=$((DONE_GUARD_FAILURES + 1))
  fi

  if is_default_template "$verify_file" verify; then
    echo "[失败] 验证记录.md 仍是默认模板"
    DONE_GUARD_FAILURES=$((DONE_GUARD_FAILURES + 1))
  fi

  failed="$(first_non_clear_label_value "$verify_file" "未通过项")"
  if [[ -n "$failed" ]]; then
    echo "[失败] 验证记录仍有未通过项: $failed"
    DONE_GUARD_FAILURES=$((DONE_GUARD_FAILURES + 1))
  fi

  pending="$(first_non_clear_label_value "$verify_file" "待补验证项")"
  if [[ -n "$pending" ]]; then
    echo "[失败] 验证记录仍有待补验证项: $pending"
    DONE_GUARD_FAILURES=$((DONE_GUARD_FAILURES + 1))
  fi

  readiness="$(verify_accept_readiness "$verify_file")"
  if [[ -n "$readiness" && "$readiness" != "是" ]]; then
    echo "[失败] 验证记录未满足进入 accept 条件: $readiness"
    DONE_GUARD_FAILURES=$((DONE_GUARD_FAILURES + 1))
  fi

  conclusion="$(accept_conclusion "$accept_file")"
  if [[ "$conclusion" != "通过" ]]; then
    echo "[失败] 验收结论不是“通过”: ${conclusion:-未填写}"
    DONE_GUARD_FAILURES=$((DONE_GUARD_FAILURES + 1))
  fi
}

describe_next_step() {
  local dir="$1"
  local spec_file repo_map_file plan_file execute_file verify_file accept_file
  local next_item missing_field pending failed conclusion

  load_state "$dir/state.json"
  spec_file="$(task_doc_path "$dir" spec)"
  repo_map_file="$(task_doc_path "$dir" repo-map)"
  plan_file="$(task_doc_path "$dir" plan)"
  execute_file="$(task_doc_path "$dir" execute)"
  verify_file="$(task_doc_path "$dir" verify)"
  accept_file="$(task_doc_path "$dir" accept)"
  next_item="$(next_plan_item "$plan_file")"

  case "$STATE_STAGE" in
    spec)
      if is_default_template "$spec_file" spec; then
        echo "补全 任务说明.md，先明确目标、范围、约束和验收标准。"
      else
        echo "任务说明已具备基础信息，下一步进入 repo-map，先定位关键目录、入口文件和影响范围。"
      fi
      ;;
    repo-map)
      if is_default_template "$repo_map_file" repo-map; then
        echo "先补全 代码库地图.md，确认关键目录、入口文件、直接相关文件和潜在影响文件。"
      else
        echo "代码边界已初步定位，下一步可基于 repo-map 补全带验证方式的执行计划。"
      fi
      ;;
    plan)
      missing_field="$(first_empty_step_field "$plan_file" "验证方式")"
      if [[ -n "$missing_field" ]]; then
        echo "先补全 执行计划.md 中每一步的验证方式：$missing_field"
      elif [[ -n "$(first_empty_step_field "$plan_file" "完成标准")" ]]; then
        echo "先补全 执行计划.md 中每一步的完成标准，再进入 execute。"
      elif [[ -n "$next_item" ]]; then
        echo "确认计划后开始执行：$next_item"
      else
        echo "补全 执行计划.md 中的步骤列表，然后进入 execute。"
      fi
      ;;
    execute)
      missing_field="$(first_empty_progress_field "$execute_file" "验证结果")"
      if [[ -n "$missing_field" ]]; then
        echo "execute 已推进但验证结果未补齐，先更新 进度记录.md：$missing_field"
      elif [[ -n "$(first_empty_progress_field "$execute_file" "是否通过")" ]]; then
        echo "execute 已推进但是否通过未回填，先补全 进度记录.md 的验证结果。"
      elif [[ -n "$next_item" ]]; then
        echo "优先处理下一条未完成步骤：$next_item"
      else
        echo "计划步骤已全部勾选，可整理 验证记录.md 并进入 verify。"
      fi
      ;;
    verify)
      if is_default_template "$verify_file" verify; then
        echo "先补全 验证记录.md，汇总验证范围、命令、预期结果、实际结果和结论。"
      else
        failed="$(first_non_clear_label_value "$verify_file" "未通过项")"
        pending="$(first_non_clear_label_value "$verify_file" "待补验证项")"
        if [[ -n "$failed" || -n "$pending" ]]; then
          echo "验证记录仍有未通过项或待补验证项，先回到 execute 处理，不要进入 accept。"
        else
          echo "验证证据已基本齐全，可基于这些证据整理 验收记录.md 并进入 accept。"
        fi
      fi
      ;;
    accept)
      if [[ "$STATE_STATUS" == "done" ]]; then
        echo "任务已标记为 done，可视情况执行 archive。"
      elif [[ "$(accept_conclusion "$accept_file")" == "有条件通过" ]]; then
        echo "当前为有条件通过，不能标记 done；请保留 active，并明确遗留问题和后续动作。"
      else
        conclusion="$(accept_conclusion "$accept_file")"
        if [[ -n "$conclusion" && "$conclusion" != "通过" ]]; then
          echo "验收结论当前为 ${conclusion}，不能标记 done；请先处理遗留问题或保留 active。"
        else
          echo "补全 验收记录.md；只有在无未勾选步骤、无阻塞、无待补验证且结论为“通过”时才可标记 done。"
        fi
      fi
      ;;
    *)
      echo "请先检查 state.json 中的阶段值是否正确。"
      ;;
  esac
}

is_task_id() {
  [[ "$1" =~ ^T[0-9]{8}-[0-9]{3}$ ]]
}

validate_stage() {
  case "$1" in
    spec|repo-map|plan|execute|verify|accept) ;;
    *) error "非法阶段: $1。允许值: spec / repo-map / plan / execute / verify / accept" ;;
  esac
}

cmd_init() {
  mkdir -p "$TASKS_DIR" "$ARCHIVE_DIR" "$TRASH_DIR"
  refresh_index ""
  log "初始化完成: $BASE_DIR"
}

cmd_new() {
  require_init
  [[ $# -ge 1 ]] || error "用法: specflow.sh new <任务标题>"

  local title id path_label task_dir ts
  title="$(sanitize_inline "$*")"
  id="$(next_id)"
  path_label="$(path_labelify "$title")"
  task_dir="$TASKS_DIR/$id-$path_label"
  ts="$(now)"

  mkdir -p "$task_dir"
  copy_templates "$task_dir"

  STATE_ID="$id"
  STATE_TITLE="$title"
  STATE_STAGE="spec"
  STATE_STATUS="active"
  STATE_LANGUAGE="$DEFAULT_LANGUAGE"
  STATE_CREATED_AT="$ts"
  STATE_UPDATED_AT="$ts"
  STATE_LAST_AGENT="system"
  STATE_LAST_SUMMARY="创建任务目录并复制默认模板"
  STATE_LAST_AT="$ts"
  write_state "$task_dir/state.json"

  refresh_index "$id"
  log "已创建任务: $id"
  log "目录: $task_dir"
}

cmd_list() {
  require_init
  local active_id
  active_id="$(current_active_task_id)"
  refresh_index "$(current_active_task_id)"
  log "工作目录: $BASE_DIR"
  log "activeTaskId: ${active_id:-none}"
  echo
  print_bucket "tasks" "$TASKS_DIR"
  print_bucket "archive" "$ARCHIVE_DIR"
  print_bucket "trash" "$TRASH_DIR"
}

cmd_status() {
  require_init

  local id dir
  if [[ $# -ge 1 ]]; then
    id="$1"
  else
    id="$(current_active_task_id)"
  fi

  refresh_index "$(current_active_task_id)"
  log "工作目录: $BASE_DIR"
  log "索引文件: $INDEX_FILE"

  if [[ -z "$id" ]]; then
    log "当前没有 activeTaskId。可执行: specflow.sh new \"任务标题\""
    return 0
  fi

  dir="$(find_task_dir "$id" || true)"
  [[ -n "$dir" ]] || error "未找到任务: $id"
  load_state "$dir/state.json"

  log "任务 ID: $STATE_ID"
  log "标题: $STATE_TITLE"
  log "阶段: $STATE_STAGE"
  log "状态: $STATE_STATUS"
  log "目录: $dir"
  log "最近操作: $STATE_LAST_AGENT | $STATE_LAST_SUMMARY | $STATE_LAST_AT"
  echo "文档:"
  echo "  - $(project_rel "$(task_doc_path "$dir" spec)")"
  echo "  - $(project_rel "$(task_doc_path "$dir" repo-map)")"
  echo "  - $(project_rel "$(task_doc_path "$dir" plan)")"
  echo "  - $(project_rel "$(task_doc_path "$dir" execute)")"
  echo "  - $(project_rel "$(task_doc_path "$dir" verify)")"
  echo "  - $(project_rel "$(task_doc_path "$dir" accept)")"
  echo "  - $(project_rel "$dir/state.json")"
  echo "下一步建议:"
  echo "  $(describe_next_step "$dir")"
}

cmd_switch() {
  require_init
  [[ $# -eq 1 ]] || error "用法: specflow.sh switch <TASK_ID>"

  local id dir ts
  id="$1"
  dir="$(find_task_dir_in_bucket "$TASKS_DIR" "$id" || true)"
  [[ -n "$dir" ]] || error "在 tasks 中未找到任务: $id"

  ts="$(now)"
  load_state "$dir/state.json"
  STATE_UPDATED_AT="$ts"
  STATE_LAST_AGENT="system"
  STATE_LAST_SUMMARY="切换为当前 activeTask"
  STATE_LAST_AT="$ts"
  write_state "$dir/state.json"

  refresh_index "$id"
  log "已切换 activeTaskId -> $id"
}

cmd_stage() {
  require_init
  [[ $# -ge 1 ]] || error "用法: specflow.sh stage <stage> [摘要]"

  local stage summary id dir ts
  stage="$1"
  shift || true
  validate_stage "$stage"

  id="$(require_active_task_id)"
  dir="$(find_task_dir_in_bucket "$TASKS_DIR" "$id" || true)"
  [[ -n "$dir" ]] || error "activeTaskId 不在 tasks 中: $id"

  ts="$(now)"
  summary="$(sanitize_inline "$*")"
  [[ -n "$summary" ]] || summary="阶段更新为 $stage"

  load_state "$dir/state.json"
  [[ "$STATE_STATUS" != "archived" && "$STATE_STATUS" != "deleted" ]] || error "当前任务状态为 $STATE_STATUS，不能更新阶段"
  ensure_stage_requirements "$stage" "$dir"
  STATE_STAGE="$stage"
  STATE_UPDATED_AT="$ts"
  STATE_LAST_AGENT="system"
  STATE_LAST_SUMMARY="$summary"
  STATE_LAST_AT="$ts"
  write_state "$dir/state.json"

  refresh_index "$id"
  log "已更新阶段: $id -> $stage"
}

cmd_complete() {
  require_init

  local id dir summary ts
  id="$(require_active_task_id)"
  dir="$(find_task_dir_in_bucket "$TASKS_DIR" "$id" || true)"
  [[ -n "$dir" ]] || error "activeTaskId 不在 tasks 中: $id"

  ts="$(now)"
  summary="$(sanitize_inline "$*")"
  [[ -n "$summary" ]] || summary="完成验收并标记为 done"

  load_state "$dir/state.json"
  if [[ "$STATE_STAGE" != "verify" && "$STATE_STAGE" != "accept" ]]; then
    error "当前阶段为 ${STATE_STAGE}，不能直接 complete。先完成 verify / accept 阶段产物。"
  fi
  done_guard_check "$dir"
  if [[ "$DONE_GUARD_FAILURES" -gt 0 ]]; then
    error "完成条件未满足，不能标记 done"
  fi
  STATE_STAGE="accept"
  STATE_STATUS="done"
  STATE_UPDATED_AT="$ts"
  STATE_LAST_AGENT="system"
  STATE_LAST_SUMMARY="$summary"
  STATE_LAST_AT="$ts"
  write_state "$dir/state.json"

  refresh_index "$id"
  log "任务已标记为 done: $id"
}

cmd_archive() {
  require_init

  local id reason dir base ts active_id
  if [[ $# -gt 0 ]] && is_task_id "$1"; then
    id="$1"
    shift
  else
    id="$(require_active_task_id)"
  fi
  reason="$(sanitize_inline "$*")"
  [[ -n "$reason" ]] || reason="归档任务"

  dir="$(find_task_dir_in_bucket "$TASKS_DIR" "$id" || true)"
  [[ -n "$dir" ]] || error "在 tasks 中未找到任务: $id"
  base="$(basename "$dir")"
  ts="$(now)"

  load_state "$dir/state.json"
  STATE_STATUS="archived"
  STATE_UPDATED_AT="$ts"
  STATE_LAST_AGENT="system"
  STATE_LAST_SUMMARY="$reason"
  STATE_LAST_AT="$ts"
  write_state "$dir/state.json"

  mv "$dir" "$ARCHIVE_DIR/$base"
  active_id="$(current_active_task_id)"
  if [[ "$active_id" == "$id" ]]; then
    active_id=""
  fi
  refresh_index "$active_id"
  log "已归档任务: $id"
}

cmd_delete() {
  require_init

  local id dir base ts active_id
  if [[ $# -gt 0 ]] && is_task_id "$1"; then
    id="$1"
  else
    id="$(require_active_task_id)"
  fi

  dir="$(find_task_dir "$id" || true)"
  [[ -n "$dir" ]] || error "未找到任务: $id"
  base="$(basename "$dir")"
  ts="$(now)"

  load_state "$dir/state.json"
  STATE_STATUS="deleted"
  STATE_UPDATED_AT="$ts"
  STATE_LAST_AGENT="system"
  STATE_LAST_SUMMARY="移动到 trash"
  STATE_LAST_AT="$ts"
  write_state "$dir/state.json"

  if [[ "$dir" != "$TRASH_DIR"/* ]]; then
    mv "$dir" "$TRASH_DIR/$base"
  fi

  active_id="$(current_active_task_id)"
  if [[ "$active_id" == "$id" ]]; then
    active_id=""
  fi
  refresh_index "$active_id"
  log "已移动到 trash: $id"
}

cmd_restore() {
  require_init
  [[ $# -eq 1 ]] || error "用法: specflow.sh restore <TASK_ID>"

  local id dir base ts active_id source_bucket
  id="$1"
  dir="$(find_task_dir_in_bucket "$ARCHIVE_DIR" "$id" || true)"
  source_bucket="archive"
  if [[ -z "$dir" ]]; then
    dir="$(find_task_dir_in_bucket "$TRASH_DIR" "$id" || true)"
    source_bucket="trash"
  fi
  [[ -n "$dir" ]] || error "在 archive/trash 中未找到任务: $id"
  base="$(basename "$dir")"
  ts="$(now)"

  mv "$dir" "$TASKS_DIR/$base"
  load_state "$TASKS_DIR/$base/state.json"
  STATE_STATUS="active"
  STATE_UPDATED_AT="$ts"
  STATE_LAST_AGENT="system"
  STATE_LAST_SUMMARY="从 $source_bucket 恢复到 tasks"
  STATE_LAST_AT="$ts"
  write_state "$TASKS_DIR/$base/state.json"

  active_id="$(current_active_task_id)"
  refresh_index "${active_id:-$id}"
  log "已恢复任务: $id"
}

cmd_next_step() {
  require_init

  local id dir
  if [[ $# -ge 1 ]]; then
    id="$1"
  else
    id="$(require_active_task_id)"
  fi

  dir="$(find_task_dir "$id" || true)"
  [[ -n "$dir" ]] || error "未找到任务: $id"

  log "任务: $id"
  echo "$(describe_next_step "$dir")"
}

cmd_verify() {
  require_init

  local id dir spec_file repo_map_file plan_file execute_file verify_file accept_file failures
  local unresolved stage_note missing_field pending failed readiness

  if [[ $# -ge 1 ]]; then
    id="$1"
  else
    id="$(require_active_task_id)"
  fi

  dir="$(find_task_dir "$id" || true)"
  [[ -n "$dir" ]] || error "未找到任务: $id"
  load_state "$dir/state.json"

  spec_file="$(task_doc_path "$dir" spec)"
  repo_map_file="$(task_doc_path "$dir" repo-map)"
  plan_file="$(task_doc_path "$dir" plan)"
  execute_file="$(task_doc_path "$dir" execute)"
  verify_file="$(task_doc_path "$dir" verify)"
  accept_file="$(task_doc_path "$dir" accept)"
  failures=0

  echo "[verify] 任务: $STATE_ID | $STATE_TITLE"
  echo "[verify] 阶段: $STATE_STAGE | 状态: $STATE_STATUS"

  for file in "$spec_file" "$repo_map_file" "$plan_file" "$execute_file" "$verify_file" "$accept_file" "$dir/state.json"; do
    if [[ -f "$file" ]]; then
      echo "[通过] 存在 $(project_rel "$file")"
    else
      echo "[失败] 缺少 $(project_rel "$file")"
      failures=$((failures + 1))
    fi
  done

  if is_default_template "$spec_file" spec; then
    echo "[失败] 任务说明.md 仍是默认模板，尚未补充任务信息"
    failures=$((failures + 1))
  elif [[ -f "$spec_file" ]]; then
    echo "[通过] 任务说明.md 已有自定义内容"
  fi

  if [[ "$STATE_STAGE" != "spec" ]]; then
    if is_default_template "$repo_map_file" repo-map; then
      echo "[失败] 代码库地图.md 仍是默认模板，尚未完成 repo-map"
      failures=$((failures + 1))
    else
      echo "[通过] 代码库地图.md 已有自定义内容"
    fi
  else
    echo "[提示] 当前仍在 spec，可在任务说明稳定后进入 repo-map。"
  fi

  if [[ "$STATE_STAGE" == "plan" || "$STATE_STAGE" == "execute" || "$STATE_STAGE" == "verify" || "$STATE_STAGE" == "accept" || "$STATE_STATUS" == "done" ]]; then
    if is_default_template "$plan_file" plan; then
      echo "[失败] 执行计划.md 仍是默认模板，尚未形成实际计划"
      failures=$((failures + 1))
    else
      echo "[通过] 执行计划.md 已有自定义内容"
    fi

    if ! grep -qE '^- \[[ x]\] ' "$plan_file"; then
      echo "[失败] 执行计划.md 缺少步骤列表"
      failures=$((failures + 1))
    else
      echo "[通过] 执行计划.md 存在步骤列表"
    fi

    missing_field="$(first_empty_step_field "$plan_file" "验证方式")"
    if [[ -n "$missing_field" ]]; then
      echo "[失败] $missing_field"
      failures=$((failures + 1))
    else
      echo "[通过] 执行计划.md 中每个步骤都已定义验证方式"
    fi

    missing_field="$(first_empty_step_field "$plan_file" "完成标准")"
    if [[ -n "$missing_field" ]]; then
      echo "[失败] $missing_field"
      failures=$((failures + 1))
    else
      echo "[通过] 执行计划.md 中每个步骤都已定义完成标准"
    fi
  else
    echo "[提示] 当前未进入 plan 之后阶段，可在完成 repo-map 后再检查计划结构。"
  fi

  unresolved="$(next_plan_item "$plan_file")"
  if [[ -z "$unresolved" && -f "$plan_file" ]] && ! is_default_template "$plan_file" plan; then
    echo "[通过] 执行计划.md 中没有未勾选步骤"
  elif [[ "$STATE_STAGE" == "verify" || "$STATE_STAGE" == "accept" || "$STATE_STATUS" == "done" ]]; then
    echo "[失败] 仍有未完成步骤: $unresolved"
    failures=$((failures + 1))
  elif [[ -n "$unresolved" ]]; then
    echo "[提示] 当前仍有未完成步骤: $unresolved"
  fi

  if [[ "$STATE_STAGE" == "execute" || "$STATE_STAGE" == "verify" || "$STATE_STAGE" == "accept" || "$STATE_STATUS" == "done" ]]; then
    if is_default_template "$execute_file" execute; then
      echo "[失败] 进度记录.md 仍是默认模板，尚未记录执行结果"
      failures=$((failures + 1))
    else
      echo "[通过] 进度记录.md 已有自定义内容"
    fi

    missing_field="$(first_empty_progress_field "$execute_file" "验证结果")"
    if [[ -n "$missing_field" ]]; then
      echo "[失败] $missing_field"
      failures=$((failures + 1))
    else
      echo "[通过] 进度记录.md 已记录验证结果"
    fi

    missing_field="$(first_empty_progress_field "$execute_file" "是否通过")"
    if [[ -n "$missing_field" ]]; then
      echo "[失败] $missing_field"
      failures=$((failures + 1))
    else
      echo "[通过] 进度记录.md 已记录是否通过"
    fi
  else
    echo "[提示] 当前未进入 execute 之后阶段，可在开始执行后再检查进度记录。"
  fi

  if [[ "$STATE_STAGE" == "verify" || "$STATE_STAGE" == "accept" || "$STATE_STATUS" == "done" ]]; then
    if is_default_template "$verify_file" verify; then
      echo "[失败] 验证记录.md 仍是默认模板，尚未形成验证证据"
      failures=$((failures + 1))
    else
      echo "[通过] 验证记录.md 已有自定义内容"
    fi

    pending="$(first_non_clear_label_value "$verify_file" "待补验证项")"
    if [[ -n "$pending" ]]; then
      echo "[失败] 验证记录仍有待补验证项: $pending"
      failures=$((failures + 1))
    else
      echo "[通过] 验证记录没有待补验证项"
    fi

    failed="$(first_non_clear_label_value "$verify_file" "未通过项")"
    if [[ -n "$failed" ]]; then
      echo "[失败] 验证记录仍有未通过项: $failed"
      failures=$((failures + 1))
    else
      echo "[通过] 验证记录没有未通过项"
    fi

    readiness="$(verify_accept_readiness "$verify_file")"
    if [[ -n "$readiness" && "$readiness" != "是" ]]; then
      echo "[失败] 验证记录显示当前不满足进入 accept: $readiness"
      failures=$((failures + 1))
    elif [[ -n "$readiness" ]]; then
      echo "[通过] 验证记录显示当前满足进入 accept"
    fi
  else
    echo "[提示] 当前未到 verify，可在完成执行后再补充验证记录。"
  fi

  if [[ "$STATE_STAGE" == "accept" || "$STATE_STATUS" == "done" ]]; then
    if is_default_template "$accept_file" accept; then
      echo "[失败] 验收记录.md 仍是默认模板"
      failures=$((failures + 1))
    else
      echo "[通过] 验收记录.md 已有自定义内容"
    fi
  else
    echo "[提示] 当前未到 accept/done，可在完成验证后再补充验收记录。"
  fi

  if [[ "$STATE_STATUS" == "done" ]]; then
    done_guard_check "$dir"
    failures=$((failures + DONE_GUARD_FAILURES))
  fi

  case "$STATE_STAGE" in
    spec)
      stage_note="当前仍在前置阶段，verify 结果仅供预检查。"
      ;;
    repo-map)
      stage_note="补全代码库地图后，再进入 plan。"
      ;;
    plan)
      stage_note="补全带验证方式和完成标准的计划后，再进入 execute。"
      ;;
    execute)
      stage_note="若以上检查全部通过且计划步骤已完成，可考虑将阶段切到 verify。"
      ;;
    verify)
      stage_note="若仍有失败项或待补验证，请先回到 execute；全部通过后再进入 accept。"
      ;;
    accept)
      stage_note="验收阶段建议同步确认最终结论和归档策略。"
      ;;
    *)
      stage_note="请检查 state.json 的阶段值。"
      ;;
  esac

  echo "[提示] $stage_note"

  if [[ "$failures" -gt 0 ]]; then
    echo "[verify] 基础校验未通过，失败项数量: $failures"
    return 1
  fi

  echo "[verify] 基础校验通过"
}

cmd_help() {
  cat <<'EOF'
SpecFlow 用法:
  specflow.sh init
  specflow.sh new <任务标题>
  specflow.sh list
  specflow.sh status [TASK_ID]
  specflow.sh switch <TASK_ID>
  specflow.sh stage <stage> [摘要]
  specflow.sh complete [摘要]
  specflow.sh next-step [TASK_ID]
  specflow.sh verify [TASK_ID]
  specflow.sh archive [TASK_ID] [原因]
  specflow.sh delete [TASK_ID]
  specflow.sh restore <TASK_ID>
  specflow.sh help

说明:
  - 任务工作目录固定为 <project-root>/.specflow/
  - 当前任务通过 .specflow/index.json 中的 activeTaskId 记录
  - 新任务默认生成六份中文文档与 state.json
  - stage 命令用于推进 spec / repo-map / plan / execute / verify / accept
  - complete 只会在计划已勾选完成、无阻塞、无待补验证且验收结论为“通过”时标记 done
  - verify 会检查 repo-map 缺失、计划未写验证方式、执行无验证结果、待补验证项和不合规的 done 状态
EOF
}

main() {
  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    init) cmd_init "$@" ;;
    new) cmd_new "$@" ;;
    list) cmd_list "$@" ;;
    status) cmd_status "$@" ;;
    switch) cmd_switch "$@" ;;
    stage) cmd_stage "$@" ;;
    complete) cmd_complete "$@" ;;
    next-step) cmd_next_step "$@" ;;
    verify) cmd_verify "$@" ;;
    archive) cmd_archive "$@" ;;
    delete) cmd_delete "$@" ;;
    restore) cmd_restore "$@" ;;
    help|-h|--help) cmd_help ;;
    *) error "未知命令: $cmd。执行 specflow.sh help 查看用法" ;;
  esac
}

main "$@"
