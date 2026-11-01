#!/bin/bash
# 新环境登记：建工作目录、生成身份卡、在环境登记.md 加行
# 用法：./scripts/new-workspace.sh <环境ID> [主机] [角色]
# 例如：./scripts/new-workspace.sh agent-01 kali 助手
set -euo pipefail

ENV_ID="${1:-}"
HOST="${2:-kali}"
ROLE="${3:-助手}"

if [ -z "$ENV_ID" ]; then
  echo "用法：$0 <环境ID> [主机] [角色]" >&2
  exit 1
fi
if ! printf '%s' "$ENV_ID" | grep -Eq '^[a-z0-9][a-z0-9-]*$'; then
  echo "环境 ID 只用小写字母、数字、连字符，且以字母或数字开头：$ENV_ID" >&2
  exit 1
fi
# 防表格注入：角色/主机含 | 会破坏登记表格结构
if printf '%s' "$ROLE$HOST" | grep -q '[|]'; then
  echo "角色/主机不能含 | 符号" >&2; exit 1
fi

CTF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WS="$CTF_ROOT/workspaces/$ENV_ID"
REGISTRY="$CTF_ROOT/环境登记.md"
NOW_BJ="$(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M')"

mkdir -p "$(dirname "$0")/../.locks"
REG_LOCK="$(dirname "$0")/../.locks/环境登记.lock"
exec 8>"$REG_LOCK"
if ! flock -w 30 8; then
  echo "拿不到环境登记锁（30 秒），稍后再试" >&2
  exit 1
fi

if [ -e "$WS" ]; then
  echo "工作目录已存在，拒绝重复建：$WS" >&2
  exit 1
fi
if grep -q "| $ENV_ID |" "$REGISTRY" 2>/dev/null; then
  echo "环境登记.md 里已有该环境 ID，拒绝重复登记：$ENV_ID" >&2
  exit 1
fi

mkdir -p "$WS/challenges" "$WS/logs"
cat > "$WS/IDENTITY.md" <<EOF
# 身份卡

- 环境 ID：$ENV_ID
- 角色：$ROLE
- 主机：$HOST
- 工作目录路径：$WS
- 会话名前缀：ctf-$ENV_ID（一题一会话，每题完整会话名 ctf-$ENV_ID-<题目编号>）
- tmux 日志路径：$WS/logs/tmux-ctf-$ENV_ID-<题目编号>.log（一题一日志）
- 开始时间（北京时间）：$NOW_BJ
- 负责分类：
- 所属对话/来源：
- 当前认领题目：
- 状态：进行中

## 说明

本卡由 scripts/new-workspace.sh 生成，登记表（../../环境登记.md）要和本卡一致，路径变了两处同步改。
EOF

cat > "$WS/notes.md" <<EOF
# 杂记（$ENV_ID）

不放 flag。flag 只记解题清单对应行。
EOF

ROW="$(printf '| %s | %s | %s | %s | ctf-%s | %s | 进行中 |' \
  "$ENV_ID" "$ROLE" "$HOST" "$WS" "$ENV_ID" "$NOW_BJ")"
if grep -q '^| --- |' "$REGISTRY"; then
  # 紧跟表头分隔行插入，保持表格不断开
  awk -v row="$ROW" '/^\| --- \|/ && !done {print; print row; done=1; next} {print}' "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
else
  printf '%s\n' "$ROW" >> "$REGISTRY"
fi

echo "已登记：$ENV_ID"
echo "工作目录：$WS"
echo "身份卡：$WS/IDENTITY.md"
echo "下一步：./scripts/start-tmux.sh $ENV_ID"
