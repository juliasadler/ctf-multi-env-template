#!/bin/bash
# 一题一会话：每道题独立 tmux 会话，独立日志文件。
# 用法：./scripts/start-tmux.sh <环境ID> <题目编号>
# 例如：./scripts/start-tmux.sh agent-01 CTF-001
# 会话名：ctf-<环境ID>-<题目编号>（如 ctf-agent-01-CTF-001）
# 日志：workspaces/<环境ID>/logs/tmux-ctf-<环境ID>-<题目编号>.log
# 工作目录：workspaces/<环境ID>/challenges/<题目编号>/
# 会话内再开窗口用于子任务分屏（如一个窗口跑 exploit，一个窗口看流量），
# 新窗口用 ./scripts/log-window.sh <会话名> [窗口名] 单独开日志。
set -euo pipefail

ENV_ID="${1:-}"
CHALLENGE="${2:-}"
if [ -z "$ENV_ID" ] || [ -z "$CHALLENGE" ]; then
  echo "用法：$0 <环境ID> <题目编号>" >&2
  echo "例如：$0 agent-01 CTF-001" >&2
  exit 1
fi
if ! printf '%s' "$ENV_ID" | grep -Eq '^[a-z0-9][a-z0-9-]*$'; then
  echo "环境 ID 只用小写字母、数字、连字符：$ENV_ID" >&2
  exit 1
fi
if ! printf '%s' "$CHALLENGE" | grep -Eq '^CTF-[0-9]{3}$'; then
  echo "题目编号格式应为 CTF-001：$CHALLENGE" >&2
  exit 1
fi

CTF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WS="$CTF_ROOT/workspaces/$ENV_ID"
CHAL_WS="$WS/challenges/$CHALLENGE"
SESSION="ctf-$ENV_ID-$CHALLENGE"
LOG="$WS/logs/tmux-$SESSION.log"

if [ ! -d "$WS" ]; then
  echo "工作目录不存在，先登记：./scripts/new-workspace.sh $ENV_ID" >&2
  exit 1
fi
if [ ! -d "$CHAL_WS" ]; then
  echo "本题工作目录还不存在，先建目录：" >&2
  echo "  mkdir -p $CHAL_WS" >&2
  echo "  # 把题目附件拷贝过去，建 过程文档.md（按 templates/过程文档模板.md）" >&2
  exit 1
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "会话已存在，不重建：$SESSION"
  echo "回连：tmux attach -t $SESSION"
  echo "日志：$LOG"
  exit 0
fi

mkdir -p "$WS/logs"
touch "$LOG"
tmux new-session -d -s "$SESSION" -c "$CHAL_WS"
tmux pipe-pane -t "$SESSION" -o "cat >> $LOG"

echo "已起会话：$SESSION"
echo "工作目录：$CHAL_WS"
echo "日志：$LOG"
echo "回连：tmux attach -t $SESSION"
echo "解题前先确认日志在记：tail -f $LOG"
echo "子任务分屏：tmux new-window -t $SESSION -n <窗口名>，再用 ./scripts/log-window.sh $SESSION <窗口名> 开日志"
