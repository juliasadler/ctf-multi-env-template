#!/bin/bash
# 起 tmux 会话并开 pipe-pane 日志。已存在则不重建，直接提示 attach。
# 用法：./scripts/start-tmux.sh <环境ID> [题目编号]
# 例如：./scripts/start-tmux.sh agent-01 CTF-001
set -euo pipefail

ENV_ID="${1:-}"
CHALLENGE="${2:-}"
if [ -z "$ENV_ID" ]; then
  echo "用法：$0 <环境ID> [题目编号]" >&2
  exit 1
fi

CTF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WS="$CTF_ROOT/workspaces/$ENV_ID"
SESSION="ctf-$ENV_ID"
LOG="$WS/logs/tmux-$SESSION.log"

if [ ! -d "$WS" ]; then
  echo "工作目录不存在，先登记：./scripts/new-workspace.sh $ENV_ID" >&2
  exit 1
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "会话已存在，不重建：$SESSION"
  echo "回连：tmux attach -t $SESSION"
  echo "日志：$LOG"
  exit 0
fi

WORKDIR="$WS"
if [ -n "$CHALLENGE" ]; then
  if [ -d "$WS/challenges/$CHALLENGE" ]; then
    WORKDIR="$WS/challenges/$CHALLENGE"
  else
    echo "注意：本题工作目录还不存在，先在 $WS/challenges/$CHALLENGE 建目录并放过程文档，再用本题窗口解题。"
    echo "本题目录：$WS/challenges/$CHALLENGE"
  fi
fi

touch "$LOG"
tmux new-session -d -s "$SESSION" -c "$WS"
tmux pipe-pane -t "$SESSION" -o "cat >> $LOG"
if [ -n "$CHALLENGE" ] && [ -d "$WS/challenges/$CHALLENGE" ]; then
  tmux new-window -t "$SESSION" -n "$CHALLENGE" -c "$WS/challenges/$CHALLENGE"
  tmux pipe-pane -t "$SESSION:$CHALLENGE" -o "cat >> $LOG"
fi

echo "已起会话：$SESSION"
echo "工作目录：$WS"
echo "日志：$LOG"
echo "回连：tmux attach -t $SESSION"
echo "解题前先确认日志在记：tail -f $LOG"
