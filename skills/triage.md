---
name: triage
description: 总入口：分诊表 + OODA 解题循环 + 状态记录 + 卡住恢复；拿到未知题型先读
triggers: ["分诊", "未知题型", "卡住", "OODA", "新题", "先看什么"]
题型: 通用
# 预留：当前 skill 文件少，frontmatter 供未来路由/检索用，暂不做自动路由
---

# Triage · 总入口与通用解题循环

> 适用题型：拿到一道题还不知道是哪类时，先读这个。分诊定题型，再去读对应的 skill。
> 前置：会用 `file`、`nmap` 基础参数，知道 flag 长什么样（`flag{...}` 类格式）。

## 前置工具（Prerequisites）

- `file` / `binwalk` / `strings`：附件与二进制初判三件套（`apt install file binwalk binutils`）。
- `nmap` / `whatweb`：Web 目标初判（`apt install nmap whatweb`）。
- `checksec`：二进制保护初判（pwntools 自带或 `apt install checksec`）。
- 都是现成小工具，赛前装好；赛中缺啥装啥。

## 触发词

- "这道题是哪类""先看什么""分诊"、拿到附件/URL 还没定题型时
- "卡住了""10 分钟没思路""换个方向"

## 能力边界

- 不讲具体题型的技术细节 → 分诊定题型后，去对应题型 skill 按清单走。
- 不写 Writeup 正文 → flag 到手后去 `writeup.md`。

## 识别特征（分诊表：看到什么 → 用哪个 skill）

| 看到什么 | 题型判断 | 去读 |
| --- | --- | --- |
| 给了 URL / IP+端口，浏览器能打开 | Web | `web.md` |
| 给了二进制 + `nc ip port` | Pwn | `pwn.md` |
| 给了二进制，要求输入正确内容 / 逆出 flag | Reverse | `reverse.md` |
| 给了一串密文 / 加密脚本 / RSA 参数 | Crypto | `crypto.md` |
| 给了图片/音频/压缩包/pcap，让"找 hidden flag" | MISC | `misc.md` |
| 给了磁盘镜像/内存 dump/日志/AD 取证材料 | 取证 | `forensics.md` |
| 给了可疑样本（PE/混淆脚本），问行为/C2 | Malware | `malware.md` |
| 只有一个人名/网名/一张照片/一个域名 | OSINT | `osint.md` |
| 题目提到 LLM/模型/提示词/越狱 | AI-ML | `ai-ml.md` |
| 题目似曾相识、记得见过同类题 | Similar-search（折叠引用） | `triage.md` 第 5 步"搜同类题解" |
| 两个以上特征混合 | 先定主入口 | 主 skill + `patterns.md` 查交叉模式 |

## 解题检查清单（按顺序走，一个 OODA 循环）

1. **设定起点与目标（Origin/Goal）**：写下来——起点是什么（URL/附件/二进制）、目标是什么（flag 格式、提交方式）。没写下来就别动手。
2. **确定性侦察（第一轮必须是这个，零思考成本）**：
   - 有 URL → `nmap` 看端口 + `whatweb` 看指纹 + 扫目录（见 `web.md` 第 1 步）。
   - 有附件 → `file` + `binwalk -e` + `strings | grep -i flag`。
   - 有二进制 → `file` + `checksec` + `strings`。
   - 侦察结果先记下来再分析，不许边扫边猜。
3. **分诊**：按上表定题型，认领对应 skill。10 分钟没思路 → 回到本文件重走一遍分诊（题型误判是头号时间黑洞）。
4. **执行 skill**：按对应 skill 的检查清单一步步走，每做一步记一条：
   - **Fact**：确认了的客观发现（如"SQL 报错注入点在 id 参数"）。
   - **Intent**：下一步要试的方向（如"试时间盲注"）。
   - **DeadEnd**：证实走不通的路 + 原因（如"WAF 拦 union，换报错注入"）。
   - 记在哪：过程文档.md（"已排除路径"一节）；模板仓里只记方法，不记具体题。
5. **卡住恢复（3 轮无新 Fact 就触发，即 Observer 漂移检测 / 模式自动注入）**：
   1. 停下，不许继续调参重试。
   2. 重读已记的 Fact + DeadEnd，找没试过的分叉。
   3. 查 `patterns.md` 有没有匹配当前特征的模式。
   4. 搜同类题解（关键词：题型 + 关键特征，如 "pwn tcache uaf writeup"）。
   5. 还卡住 → 标记 DeadEnd，换题或求助（带上已排除路径，别空口问）。
6. **收尾**：flag 到手后按 `writeup.md` 记 Writeup；把过程中发现的新模式/新坑回填到对应 skill（见《使用与协同评估.md》新增流程）。

## 状态外置（多环境共享事实源）

- Fact / Intent / DeadEnd **必须写进外部表**（过程文档.md"已排除路径"一节，或 notes.md），不靠 agent 的记忆——上下文一切换，记忆就丢。
- 多环境 / 多 agent 并行解题时，这张外部状态表就是共享事实源：谁认领了哪道题、哪条路已证实走不通，都以表为准，不口头传、不靠猜。
- 模板仓的 skills/ 里只沉淀通用方法，不记具体题目的状态（见《协议与约束.md》第 8 条）。

## 常用工具

| 工具 | 用来干什么 | 一句话用法 |
| --- | --- | --- |
| file / binwalk / strings | 附件/二进制初判 | 三连先跑，5 分钟定方向 |
| nmap / whatweb | Web 目标初判 | 端口 + 指纹，决定深挖哪 |
| checksec | 二进制保护初判 | pwn/reverse 分流依据 |

## 常见坑

- 坑 1：跳过第 2 步直接开干 → 侦察 5 分钟能省 1 小时弯路，永远先侦察。
- 坑 2：题型定错了死磕 → 特征对不上清单就回分诊表重判，别"感觉像 Web"。
- 坑 3：DeadEnd 不记 → 同一个坑踩两遍。证实走不通的路必须写下来。
- 坑 4：一个人闷头卡 1 小时 → 3 轮无进展就按第 5 步走，换题不丢人。
