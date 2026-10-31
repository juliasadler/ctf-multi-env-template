#!/bin/bash
# 带锁改清单状态，避免两个环境同时手工改表撞题。
# 用法：
#   ./scripts/update-status.sh <题目编号> <环境ID> 已认领
#   ./scripts/update-status.sh <题目编号> <环境ID> 进行中
#   ./scripts/update-status.sh <题目编号> <环境ID> 已完成 --flag 'flag{...}' [--doc 'workspaces/<环境ID>/challenges/<编号>/过程文档.md']
#   ./scripts/update-status.sh <题目编号> <环境ID> 已放弃 --note '原因'
#   ./scripts/update-status.sh <题目编号> <环境ID> 阻塞 --note '卡点'
#   ./scripts/update-status.sh <题目编号> <环境ID> 未开始 --note '归还原因'
#   ./scripts/update-status.sh <题目编号> <环境ID> 待办 --note '分诊结论'
#   ./scripts/update-status.sh <题目编号> <环境ID> 已认领 --force  # 接管超1小时失联的认领
#   ./scripts/update-status.sh <题目编号> <环境ID> 进行中 --progress '当前进展一句话'
#   ./scripts/update-status.sh <题目编号> <环境ID> 进行中 --flag 'flag{...}'  # flag 一出来就记
# 状态流转只允许：未开始->已认领/待办；待办->已认领/未开始；已认领/进行中->进行中/已完成/已放弃/阻塞；
# 已放弃/阻塞->已认领（重新认领时认领者改为新环境）；已完成不再改回。
# 认领超时：已认领超 1 小时未动到进行中视为失联，其他环境可用 --force 接管。
# 平台提交列不在本脚本里改，提交平台后手工把那列改成已提交，并注明提交时间。
set -euo pipefail

CHALLENGE="${1:-}"
ENV_ID="${2:-}"
NEW_STATUS="${3:-}"
FLAG=""
DOC=""
NOTE=""
FORCE=""
PROGRESS=""
shift 3 || true
while [ $# -gt 0 ]; do
  case "$1" in
    --flag) FLAG="${2:-}"; shift 2 ;;
    --doc) DOC="${2:-}"; shift 2 ;;
    --note) NOTE="${2:-}"; shift 2 ;;
    --force) FORCE="1"; shift ;;
    --progress) PROGRESS="${2:-}"; shift 2 ;;
    *) echo "未知参数：$1" >&2; exit 1 ;;
  esac
done

if [ -z "$CHALLENGE" ] || [ -z "$ENV_ID" ] || [ -z "$NEW_STATUS" ]; then
  echo "用法：$0 <题目编号> <环境ID> <新状态> [--flag ...] [--doc ...] [--note ...]" >&2
  exit 1
fi
case "$NEW_STATUS" in
  未开始|待办|已认领|进行中|已完成|已放弃|阻塞) ;;
  *) echo "状态只能是：未开始 / 待办 / 已认领 / 进行中 / 已完成 / 已放弃 / 阻塞" >&2; exit 1 ;;
esac
if [ "$NEW_STATUS" = "已完成" ] && [ -z "$FLAG" ]; then
  echo "改成已完成时必须带 --flag，flag 只记本地清单" >&2
  exit 1
fi

CTF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIST="$CTF_ROOT/解题清单.md"
mkdir -p "$CTF_ROOT/.locks"
LOCK_FILE="$CTF_ROOT/.locks/解题清单.lock"
NOW_BJ="$(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M')"

# flock 内用 python 按表头列名改行，避免手工 sed 弄断表格。
# 锁文件描述符 9，整个读改写过程都在锁内，两个人同时跑时只有一个能进。
exec 9>"$LOCK_FILE"
if ! flock -w 30 9; then
  echo "拿不到清单锁（30 秒），可能有其他环境正在改表，稍后再试，不要手工强改" >&2
  exit 1
fi

CHALLENGE="$CHALLENGE" ENV_ID="$ENV_ID" NEW_STATUS="$NEW_STATUS" \
FLAG="$FLAG" DOC="$DOC" NOTE="$NOTE" FORCE="$FORCE" PROGRESS="$PROGRESS" NOW_BJ="$NOW_BJ" LIST="$LIST" \
python3 - <<'PY'
import os, sys

def clean(s):
    """防表格注入：| 会破坏 markdown 表格结构，换行会断行"""
    return s.replace("|", " ").replace("\n", " ").replace("\r", " ")

challenge = os.environ["CHALLENGE"]
env_id = os.environ["ENV_ID"]
new_status = os.environ["NEW_STATUS"]
flag = clean(os.environ["FLAG"])
doc = clean(os.environ["DOC"])
note = clean(os.environ["NOTE"])
progress = clean(os.environ["PROGRESS"])
now = os.environ["NOW_BJ"]
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
for col in ["编号", "状态", "认领者"]:
    if col not in idx:
        print(f"清单表头缺列：{col}", file=sys.stderr)
        sys.exit(1)

allowed = {
    "未开始": {"已认领", "待办"},
    "待办": {"已认领", "未开始", "已放弃"},
    "已认领": {"进行中", "已完成", "已放弃", "阻塞"},
    "进行中": {"进行中", "已完成", "已放弃", "阻塞"},
    "已放弃": {"已认领"},
    "阻塞": {"已认领", "进行中", "已完成", "已放弃"},
    "已完成": set(),
}
found = False
for i in range(header_idx + 2, len(lines)):
    line = lines[i]
    if not line.startswith("|"):
        continue
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cells) != len(headers):
        continue
    if cells[idx["编号"]] != challenge:
        continue
    found = True
    if "示例" in line:
        print("这是格式示例，不要认领", file=sys.stderr)
        sys.exit(1)
    old_status = cells[idx["状态"]]
    old_claimer = cells[idx["认领者"]]
    force = os.environ.get("FORCE", "")
    # --force 接管特例：已认领→已认领时跳过流转检查，走下面的失联接管逻辑
    is_takeover = (new_status == "已认领" and old_status == "已认领" and force)
    if not is_takeover and new_status not in allowed.get(old_status, set()):
        # 已认领→已认领（无 force）：检查是否失联，给友好提示
        if new_status == "已认领" and old_status == "已认领":
            from datetime import datetime, timedelta, timezone
            try:
                ct_s = cells[idx["认领时间（北京时间）"]] if "认领时间（北京时间）" in idx else "-"
                ct = datetime.strptime(ct_s, "%Y-%m-%d %H:%M")
                bj_now = datetime.now(timezone(timedelta(hours=8))).replace(tzinfo=None)
                if (bj_now - ct) > timedelta(hours=1):
                    print(f"这题已失联（{old_claimer}，{ct_s}），加 --force 接管：update-status.sh {challenge} {env_id} 已认领 --force", file=sys.stderr)
                    sys.exit(1)
            except (ValueError, TypeError, KeyError):
                pass
        print(f"不允许的状态流转：{old_status} -> {new_status}（当前认领者：{old_claimer}）", file=sys.stderr)
        sys.exit(1)
    if new_status == "已认领" and old_status == "已认领" and old_claimer not in ("-", "", env_id):
        # 检查是否超时（1小时）：认领时间超1h且还在已认领，视为失联
        from datetime import datetime, timedelta, timezone
        claim_time_s = cells[idx["认领时间（北京时间）"]] if "认领时间（北京时间）" in idx else "-"
        is_stale = False
        try:
            claim_time = datetime.strptime(claim_time_s, "%Y-%m-%d %H:%M")
            bj_now = datetime.now(timezone(timedelta(hours=8))).replace(tzinfo=None)
            is_stale = (bj_now - claim_time) > timedelta(hours=1)
        except (ValueError, TypeError):
            pass
        if is_stale and force:
            old_note = cells[idx["备注"]] if "备注" in idx else "-"
            takeover_note = f"接管自{old_claimer}（认领超时1h失联）"
            if "备注" in idx:
                cells[idx["备注"]] = takeover_note if old_note in ("-", "") else old_note + "；" + takeover_note
            # 允许接管：把旧认领者视为可覆盖
            old_claimer = env_id
            print(f"已接管失联认领：原认领者 {cells[idx['认领者']]}，已记入备注", file=sys.stderr)
        elif not is_stale:
            print(f"这题已被 {old_claimer} 认领（{claim_time_s}，未超时），不要抢；用 check-stale.sh 查失联", file=sys.stderr)
            sys.exit(1)
        else:
            print(f"这题已失联（{old_claimer}，{claim_time_s}），加 --force 接管", file=sys.stderr)
            sys.exit(1)
    if new_status in ("已认领", "进行中", "已完成") and old_claimer not in ("-", "", env_id) and old_status not in ("已放弃", "阻塞", "未开始", "待办"):
        print(f"这题已被 {old_claimer} 认领，当前状态 {old_status}，不要抢", file=sys.stderr)
        sys.exit(1)
    cells[idx["状态"]] = new_status
    if new_status == "已认领":
        cells[idx["认领者"]] = env_id
        if "认领时间（北京时间）" in idx:
            cells[idx["认领时间（北京时间）"]] = now
    if new_status == "已完成":
        cells[idx["认领者"]] = env_id
        if "完成时间（北京时间）" in idx:
            cells[idx["完成时间（北京时间）"]] = now
        if "flag" in idx:
            cells[idx["flag"]] = flag
    # flag 一出来就记：进行中时带 --flag 直接写 flag 列，不等到完成（防崩溃丢失）
    if new_status == "进行中" and flag and "flag" in idx:
        cells[idx["flag"]] = flag
        if doc and "过程文档路径" in idx:
            cells[idx["过程文档路径"]] = doc
    if note and "备注" in idx:
        cells[idx["备注"]] = note
    if progress and "进度摘要" in idx:
        cells[idx["进度摘要"]] = progress + f"（{now}）"
    lines[i] = "| " + " | ".join(cells) + " |"
    break

if not found:
    print(f"清单里没有这题：{challenge}", file=sys.stderr)
    sys.exit(1)

open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
print(f"已更新：{challenge} -> {new_status}（{env_id}，北京时间 {now}）")
PY

