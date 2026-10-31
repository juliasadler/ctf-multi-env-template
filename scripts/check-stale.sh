#!/bin/bash
# 查失联认领：列出"已认领"超过 1 小时还没动到"进行中"的题目。
# 用法：./scripts/check-stale.sh
# 认领超时 1 小时后，其他环境可用 update-status.sh --force 接管。
set -euo pipefail

CTF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIST="$CTF_ROOT/解题清单.md"

LIST="$LIST" python3 - <<'PY'
import os, re, sys
from datetime import datetime, timedelta

path = os.environ["LIST"]
lines = open(path, encoding="utf-8").read().splitlines()
header_idx = None
for i, line in enumerate(lines):
    if line.startswith("| 编号 |"):
        header_idx = i
        break
if header_idx is None:
    print("清单里找不到表头", file=sys.stderr)
    sys.exit(1)

headers = [c.strip() for c in lines[header_idx].strip().strip("|").split("|")]
idx = {name: j for j, name in enumerate(headers)}
now = datetime.now().astimezone()  # 本地时间，换算成北京时间比较
# 北京时间 = UTC+8
from datetime import timezone
bj_now = datetime.now(timezone(timedelta(hours=8))).replace(tzinfo=None)

stale = []
for i in range(header_idx + 2, len(lines)):
    line = lines[i]
    if not line.startswith("|"):
        continue
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cells) != len(headers):
        continue
    if "示例" in line:
        continue
    if cells[idx["状态"]] != "已认领":
        continue
    claim_time_s = cells[idx.get("认领时间（北京时间）", -1)] if "认领时间（北京时间）" in idx else "-"
    try:
        claim_time = datetime.strptime(claim_time_s, "%Y-%m-%d %H:%M")
    except (ValueError, TypeError):
        continue
    age = bj_now - claim_time
    if age > timedelta(hours=1):
        hours = age.total_seconds() / 3600
        stale.append((cells[idx["编号"]], cells[idx["认领者"]], claim_time_s, f"{hours:.1f}h"))

if not stale:
    print("没有失联认领（已认领超 1 小时无进展的题目）。")
else:
    print(f"发现 {len(stale)} 道失联题目（已认领超 1 小时未动到进行中）：")
    for num, claimer, t, age in stale:
        print(f"  {num} | 认领者：{claimer} | 认领时间：{t} | 已过去：{age}")
    print("")
    print("接管方法：./scripts/update-status.sh <编号> <你的环境ID> 已认领 --force")
    print("接管后旧认领者会记入备注，原环境回来后先看备注再动手。")
PY
