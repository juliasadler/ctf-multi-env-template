#!/bin/bash
# 认领前复查：看某题在清单里是哪一行、什么状态、有没有人认领。
# 用法：./scripts/check-claim.sh <题目编号>
# 例如：./scripts/check-claim.sh CTF-001
set -euo pipefail

CHALLENGE="${1:-}"
if [ -z "$CHALLENGE" ]; then
  echo "用法：$0 <题目编号>" >&2
  exit 1
fi

CTF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIST="$CTF_ROOT/解题清单.md"

ROW="$(grep -F "| $CHALLENGE |" "$LIST" || true)"
if [ -z "$ROW" ]; then
  echo "清单里没有这题：$CHALLENGE（先按 challenges/README.md 新增题目）"
  exit 1
fi

echo "$ROW"
case "$ROW" in
  *示例*) echo "结论：这是格式示例，不要认领。"; exit 0 ;;
esac
case "$ROW" in
  *"| 未开始 |"*) echo "结论：可认领。认领后先把状态改成已认领再动手。" ;;
  *"| 已完成 |"*) echo "结论：已完成，不要重复做。" ;;
  *) echo "结论：已被认领 / 进行中 / 阻塞 / 已放弃，请看认领者和备注，不要直接动手。" ;;
esac
