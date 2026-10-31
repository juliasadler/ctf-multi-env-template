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
  *"| 待办 |"*) echo "结论：已分诊排队中，可认领（update-status.sh 改成已认领）。" ;;
  *"| 已完成 |"*) echo "结论：已完成，不要重复做。" ;;
  *) echo "结论：已被认领 / 进行中 / 阻塞 / 已放弃，请看认领者和备注，不要直接动手。" ;;
esac

# 失联检查：已认领超 1 小时未动到进行中，提示可接管（按表头名取列，列顺序变了也不怕）
if echo "$ROW" | grep -q "| 已认领 |"; then
  STALE_MSG="$(TZ=Asia/Shanghai LIST="$LIST" ROW="$ROW" python3 - <<'PYEOF2'
import os
from datetime import datetime, timedelta
row = os.environ["ROW"]
lst = open(os.environ["LIST"], encoding="utf-8").read().splitlines()
headers = []
for line in lst:
    if line.startswith("| 编号 |"):
        headers = [c.strip() for c in line.strip().strip("|").split("|")]
        break
cells = [c.strip() for c in row.strip().strip("|").split("|")]
idx = {h: i for i, h in enumerate(headers)}
try:
    ct_s = cells[idx["认领时间（北京时间）"]]
    ct = datetime.strptime(ct_s, "%Y-%m-%d %H:%M")
    now = datetime.now()  # 调用方已设 TZ=Asia/Shanghai，与清单口径一致
    if (now - ct) > timedelta(hours=1):
        print(f"STALE|{ct_s}")
    else:
        print("OK")
except Exception:
    print("UNKNOWN")
PYEOF2
)"
  case "$STALE_MSG" in
    STALE*)
      CLAIM_T="${STALE_MSG#STALE|}"
      echo "⚠️ 认领已超过 1 小时无进展（$CLAIM_T），疑似失联。"
      echo "   可用 ./scripts/check-stale.sh 复查，或 ./scripts/update-status.sh <编号> <你的环境ID> 已认领 --force 接管。"
      ;;
  esac
fi
