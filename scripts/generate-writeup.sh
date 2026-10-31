#!/bin/bash
# generate-writeup.sh — 从解题清单 + 过程文档半自动生成 Writeup 初稿
# 用法：./scripts/generate-writeup.sh <题目编号> <环境ID> [--match 比赛名称] [--team 队伍名]
# 输出：workspaces/<环境ID>/challenges/<题目编号>/Writeup-<题目编号>.md
# 生成后人工补 [TODO] 项（截图、一二三血、润色），过检查清单再提交。
set -euo pipefail

CID="${1:?用法：$0 <题目编号> <环境ID> [--match 比赛名称] [--team 队伍名]}"
ENV_ID="${2:?用法：$0 <题目编号> <环境ID> [--match 比赛名称] [--team 队伍名]}"
MATCH=""
TEAM=""
shift 2
while [ $# -gt 0 ]; do
  case "$1" in
    --match) MATCH="${2:?}"; shift 2 ;;
    --team) TEAM="${2:?}"; shift 2 ;;
    *) echo "未知参数：$1" >&2; exit 1 ;;
  esac
done

if ! printf '%s' "$CID" | grep -Eq '^CTF-[0-9]{3}$'; then
  echo "题目编号格式须为 CTF-001：$CID" >&2; exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIST="$ROOT/解题清单.md"
TEMPLATE="$ROOT/templates/Writeup模板.md"
CH_DIR="$ROOT/workspaces/$ENV_ID/challenges/$CID"
PROC="$CH_DIR/过程文档.md"
OUT="$CH_DIR/Writeup-$CID.md"

[ -f "$LIST" ] || { echo "找不到解题清单：$LIST" >&2; exit 1; }
[ -f "$TEMPLATE" ] || { echo "找不到模板：$TEMPLATE" >&2; exit 1; }
[ -f "$PROC" ] || { echo "找不到过程文档：$PROC（先写过程文档再生成）" >&2; exit 1; }
[ -f "$OUT" ] && { echo "已存在：$OUT（如需重生成请先备份删除）" >&2; exit 1; }

MATCH="$MATCH" TEAM="$TEAM" CID="$CID" LIST="$LIST" PROC="$PROC" \
TEMPLATE="$TEMPLATE" OUT="$OUT" python3 << 'PYEOF'
import os, re, sys

cid = os.environ["CID"]
lst = open(os.environ["LIST"], encoding="utf-8").read()
proc = open(os.environ["PROC"], encoding="utf-8").read()
tpl = open(os.environ["TEMPLATE"], encoding="utf-8").read()

# --- 从解题清单取行 ---
headers, row = None, None
for line in lst.splitlines():
    if not line.startswith("|"):
        continue
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if headers is None and "编号" in cells:
        headers = cells
        continue
    if headers:
        if len(cells) != len(headers):
            sys.exit(f"解题清单表格列数异常（{len(cells)} vs {len(headers)}），可能有单元格含未过滤的 |")
        if cells[headers.index("编号")] == cid:
            row = dict(zip(headers, cells))
            break
if not row:
    sys.exit(f"解题清单中找不到 {cid}")

if row.get("状态") not in ("已完成", "进行中"):
    print(f"警告：{cid} 状态为「{row.get('状态')}」，Writeup 通常在解出后生成", file=sys.stderr)

# --- 从过程文档取节 ---
def section(name):
    # 取 "## <name>" 到下一个 "## " 之间的内容
    m = re.search(rf"^## {re.escape(name)}\s*\n(.*?)(?=^## |\Z)", proc,
                  re.MULTILINE | re.DOTALL)
    return m.group(1).strip() if m else ""

def field(name):
    # 取 "- <name>：" 行的值
    m = re.search(rf"^- {re.escape(name)}：(.*)$", proc, re.MULTILINE)
    return m.group(1).strip() if m else ""

mapping = {
    "比赛名称": os.environ["MATCH"],
    "队伍名": os.environ["TEAM"],
    "认领者": row.get("认领者", ""),
    "题目编号": cid,
    "题目标题": row.get("题目", ""),
    "分类": row.get("分类", ""),
    "分值": row.get("分值", ""),
    "认领时间": row.get("认领时间（北京时间）", ""),
    "完成时间": row.get("完成时间（北京时间）", ""),
    "flag": row.get("flag", ""),
    "提交人": row.get("提交人", ""),
    "平台提交": row.get("平台提交", ""),
    "题目简述": section("题目简述") or field("题目简述"),
    "思路": section("思路"),
    "步骤": section("步骤"),
    "遇到的坑": section("遇到的坑"),
    "关键payload": section("关键 payload（结构）"),
}

# 复现方法只取"结果"节里"复现方法："后面的内容
_result = section("结果")
_m = re.search(r"复现方法：(.*?)(?=\n- |\Z)", _result, re.DOTALL)
_repro = _m.group(1).strip() if _m else _result
mapping["复现方法"] = _repro

# 单遍替换：先算好所有替换值，再用 re.sub 回调一次完成
# 防过程文档内容含字面 {{占位符}} 被二次替换
_repl = {}
missing = []
for k, v in mapping.items():
    if not v or v == "-":
        missing.append(k)
        v = f"[TODO:{k}]"
    # 表格注入防护：占位符替换的值里 | 换空格
    v = v.replace("|", " ")
    _repl["{{" + k + "}}"] = v
out = re.sub(r"\{\{[^}]+\}\}", lambda m: _repl.get(m.group(0), m.group(0)), tpl)

with open(os.environ["OUT"], "w", encoding="utf-8") as f:
    f.write(out)

print(f"已生成：{os.environ['OUT']}")
todo_count = out.count("[TODO")
print(f"待人工补：{todo_count} 处 [TODO]（含截图、一二三血、润色）")
if missing:
    print("缺失来源字段（已标 [TODO:字段名]）：" + "、".join(missing))
PYEOF
