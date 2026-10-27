#!/bin/bash
# 给 tmux 会话里的某个窗口开 pipe-pane 日志。
# 用法：./scripts/log-window.sh <会话名> [窗口名]
# 例如：./scripts/log-window.sh ctf-agent-01 CTF-001
# 不给窗口名时，给当前窗口开日志。
# 注意：tmux 里新开的窗口默认不继承主窗口的 pipe-pane，必须单独开一次。
set -euo pipefail

SESSION="${1:-}"
WINDOW="${2:-}"
if [ -z "$SESSION" ]; then
  echo "用法：$0 <会话名> [窗口名]" >&2
  exit 1
fi
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "会话不存在：$SESSION，先跑 start-tmux.sh" >&2
  exit 1
fi

# 从会话名反推环境 ID 和日志路径：ctf-<环境ID> -> workspaces/<环境ID>/logs/...
ENV_ID="${SESSION#ctf-}"
CTF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$CTF_ROOT/workspaces/$ENV_ID/logs/tmux-$SESSION.log"
mkdir -p "$(dirname "$LOG")"
touch "$LOG"

TARGET="$SESSION"
if [ -n "$WINDOW" ]; then
  TARGET="$SESSION:$WINDOW"
fi
tmux pipe-pane -t "$TARGET" -o "cat >> $LOG"
echo "已给 $TARGET 开日志：$LOG"
echo "确认：tail -f $LOG"
