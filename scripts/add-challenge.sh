#!/bin/bash
# 新增题目：自动取号、建 challenges/ 目录、往解题清单插行，全程带锁。
# 用法：./scripts/add-challenge.sh <题名> <分类> <分值> [难度] [简称]
# 例如：./scripts/add-challenge.sh "简单的登录" web 100 易 login
# 分类：web / pwn / crypto / reverse / misc / forensics / osint / ai-ml / malware
# 难度：易 / 中 / 难（默认：中）
# 简称：英文短横线命名（默认：challenge），用于目录名
set -euo pipefail

TITLE="${1:-}"
CATEGORY="${2:-}"
SCORE="${3:-}"
DIFFICULTY="${4:-中}"
SLUG="${5:-challenge}"

if [ -z "$TITLE" ] || [ -z "$CATEGORY" ] || [ -z "$SCORE" ]; then
  echo "用法：$0 <题名> <分类> <分值> [难度] [简称]" >&2
  exit 1
fi
case "$CATEGORY" in
  web|pwn|crypto|reverse|misc|forensics|osint|ai-ml|malware) ;;
  *) echo "分类只能是：web / pwn / crypto / reverse / misc / forensics / osint / ai-ml / malware" >&2; exit 1 ;;
esac
if ! printf '%s' "$SCORE" | grep -Eq '^[0-9]+$'; then
  echo "分值必须是数字：$SCORE" >&2; exit 1
fi
case "$DIFFICULTY" in
  易|中|难) ;;
  *) echo "难度只能是：易 / 中 / 难" >&2; exit 1 ;;
esac
if ! printf '%s' "$SLUG" | grep -Eq '^[a-z0-9][a-z0-9-]*$'; then
  echo "简称只用小写字母、数字、连字符：$SLUG" >&2; exit 1
fi
# 防表格注入：题名含 | 或换行会破坏清单表格结构
if printf '%s' "$TITLE" | grep -q '[|]'; then
  echo "题名不能含 | 符号：$TITLE" >&2; exit 1
fi
TITLE="$(printf '%s' "$TITLE" | tr -d '\n\r')"

CTF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIST="$CTF_ROOT/解题清单.md"
CHAL_DIR="$CTF_ROOT/challenges"
TEMPLATE="$CTF_ROOT/templates/题目说明模板.md"
mkdir -p "$CTF_ROOT/.locks"
LOCK_FILE="$CTF_ROOT/.locks/解题清单.lock"

exec 9>"$LOCK_FILE"
if ! flock -w 30 9; then
  echo "拿不到清单锁（30 秒），可能有其他环境正在改表，稍后再试" >&2
  exit 1
fi

TITLE="$TITLE" CATEGORY="$CATEGORY" SCORE="$SCORE" DIFFICULTY="$DIFFICULTY" \
SLUG="$SLUG" LIST="$LIST" CHAL_DIR="$CHAL_DIR" TEMPLATE="$TEMPLATE" \
python3 - <<'PY'
import os, re, sys

title = os.environ["TITLE"]
category = os.environ["CATEGORY"]
score = os.environ["SCORE"]
difficulty = os.environ["DIFFICULTY"]
slug = os.environ["SLUG"]
path = os.environ["LIST"]
chal_dir = os.environ["CHAL_DIR"]
template = os.environ["TEMPLATE"]

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

# 找最大号（跳过 CTF-000 示例）
max_num = 0
for i in range(header_idx + 2, len(lines)):
    line = lines[i]
    if not line.startswith("|"):
        continue
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cells) != len(headers):
        continue
    m = re.match(r"CTF-(\d+)", cells[0])
    if m and cells[0] != "CTF-000":
        max_num = max(max_num, int(m.group(1)))

new_num = max_num + 1
new_id = f"CTF-{new_num:03d}"

# 建题目目录
dir_name = f"{new_id}-{slug}"
full_dir = os.path.join(chal_dir, category, dir_name)
if os.path.exists(full_dir):
    print(f"目录已存在，换个简称：{full_dir}", file=sys.stderr)
    sys.exit(1)
os.makedirs(full_dir)

# 题目说明.md（从模板生成）
if os.path.exists(template):
    tpl = open(template, encoding="utf-8").read()
    tpl = tpl.replace("{{题目编号}}", new_id).replace("{{题名}}", title).replace("{{分类}}", category)
else:
    tpl = f"# {new_id} {title}\n\n- 分类：{category}\n- 分值：{score}\n- 难度：{difficulty}\n"
open(os.path.join(full_dir, "题目说明.md"), "w", encoding="utf-8").write(tpl)

# 按表头列名组装行（缺列就填 -，保证列数对齐）
col_val = {
    "编号": new_id,
    "题目": title,
    "分类": category,
    "难度": difficulty,
    "分值": score,
    "题目路径": f"challenges/{category}/{dir_name}/题目说明.md",
    "状态": "未开始",
    "进度摘要": "-",
    "认领者": "-",
    "认领时间（北京时间）": "-",
    "完成时间（北京时间）": "-",
    "flag": "-",
    "平台提交": "未提交",
    "提交人": "-",
    "过程文档路径": "-",
    "备注": "-",
}
row = "| " + " | ".join(col_val.get(h, "-") for h in headers) + " |"

# 插到表格末尾（分隔行之后第一个非表格行之前，简化：直接追加到文件末尾的表格区）
# 找到表格最后一行
insert_at = len(lines)
for i in range(header_idx + 2, len(lines)):
    if lines[i].startswith("|"):
        insert_at = i + 1
lines.insert(insert_at, row)
open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
print(f"已新增：{new_id} {title}（{category}，{score}分，{difficulty}）")
print(f"题目目录：challenges/{category}/{dir_name}/")
print(f"下一步：./scripts/check-claim.sh {new_id} 确认，然后认领")
PY
