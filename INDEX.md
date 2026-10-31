# CTF 总索引

> 本文件是仓库的总目录索引：每个目录/文件是干什么的、在哪。
> 题目、环境、认领的**实时状态**看对应的清单文件，不在这里抄表，避免两处对不上。

## 根目录

- `README.md`——使用指南：模板与实战实例的划分、目录结构、从模板建实例、快速开始 5 步、铁律摘要
- `协议与约束.md`——最高约束：权威划分、身份登记、编号、认领流程、冲突处理、工作隔离、tmux 日志、flag 隐私（动手前必读，冲突以它为准）
- `INDEX.md`——本文件：总目录索引
- `解题清单.md`——认领的唯一权威（格式示例）：题目、状态、认领者、flag、平台提交、过程文档路径
- `环境登记.md`——身份的唯一权威（格式示例）：环境 ID、角色、主机、工作目录、tmux 会话
- `资源登记.md`——本地服务与端口占用登记，并行环境起服务前先登记，避免抢端口
- `更新日志.md`——模板结构改动记录（只记结构，不记单题进度）
- `.gitignore`——实战实例必须挡住：清单、登记、身份卡、日志、`.conflict`（模板仓内为示例配置）
- `LICENSE`——MIT

## `challenges/` —— 题目正本区（只读心态）

- `README.md`——新增题目流程
- `{{分类}}/{{编号}}-{{简称}}/题目说明.md`——按 `templates/题目说明模板.md` 写；附件原样存放，任何环境不直接在正本上解题

## `workspaces/` —— 各环境工作区（一环境一子目录）

- `README.md`——工作区结构说明
- `{{环境ID}}/IDENTITY.md`——身份卡（由 `scripts/new-workspace.sh` 生成，须与环境登记一致）
- `{{环境ID}}/challenges/{{编号}}/`——本题工作副本 + `过程文档.md` + 解题文件（按 `templates/过程文档模板.md` 写）
- `{{环境ID}}/logs/`——tmux 日志（`pipe-pane` 落盘）
- `{{环境ID}}/notes.md`——杂记（不放 flag）

## `templates/` —— 文档模板

- `身份卡模板.md` / `过程文档模板.md` / `题目说明模板.md`

## `scripts/` —— 运维脚本（`chmod +x` 后用）

- `new-workspace.sh`——建工作目录 + 生成身份卡 + 登记环境
- `start-tmux.sh`——起 `ctf-<环境ID>` 会话并开日志
- `log-window.sh`——给 tmux 新窗口开日志
- `check-claim.sh`——查题目认领状态
- `update-status.sh`——带锁改清单状态（认领/进行中/完成/放弃/阻塞）

## `skills/` —— 题型解题方法沉淀（只讲方法，不写具体题目的答案）

- `README.md`——skill 使用与新增规范（含外部引用说明）
- `skill-template.md`——新 skill 空模板
- `triage.md`——总入口：分诊表、OODA 解题循环、状态记录、卡住恢复（先读）
- `patterns.md`——跨题型模式速查（特征→模式→去哪）、绕过策略通用原则
- `web.md` / `crypto.md` / `misc.md` / `reverse.md` / `pwn.md`——各题型：识别特征 → 检查清单 → 常用工具 → 常见坑
- `forensics.md` / `osint.md` / `ai-ml.md` / `malware.md`——新增题型 skill（取证/OSINT/AI 攻防/样本分析）
- `writeup.md`——赛后 Writeup 结构与脱敏自查

## `prompts/` —— Agent 解题规范（与 `skills/` 并列，瘦身版）

- `ctf-solve.md`——Agent 瘦身解题规范：只规定目录、工具边界、停机闸门；本地小模型 Agent 解题用（云端大模型/人工走 `skills/triage.md`，按「模型分档」选用）
- `STATUS-template.md`——状态卡模板：category/flag/hypothesis/facts/next 四段式，多环境共享事实源

当前已登记环境、已认领题目，以 `环境登记.md` 和 `解题清单.md` 的最新内容为准，本索引不重复抄表，避免两处对不上。
