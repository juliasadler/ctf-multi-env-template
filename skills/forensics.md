---
name: forensics
description: 取证题解题方法：磁盘/内存/日志/取证式流量问答（攻击者是谁/被删文件）
triggers: [".img", ".raw", "攻击者IP", "被删文件", "auth.log", "volatility", "内存dump"]
题型: Forensics
# 预留：当前 skill 文件少，frontmatter 供未来路由/检索用，暂不做自动路由
---

# Forensics · 数字取证

> 适用题型：给了磁盘镜像（.img/.E01）、内存 dump（.raw/.vmem）、系统日志、流量包里的取证问答（"攻击者 IP 是谁""被删的文件内容"）。
> 前置：会用 `strings`、`xxd`，知道文件系统大意（EXT4/NTFS 有文件名和删除标记）。

## 前置工具（Prerequisites）

- sleuthkit（fls/icat/mactime）：磁盘镜像分析（`apt install sleuthkit`）。
- volatility3：内存取证（`git clone` + pip 依赖，赛前装好）。
- Wireshark / tshark：流量取证（`apt install wireshark tshark`）。
- 镜像体积大，工具赛前装好；`strings` / `grep` 系统自带兜底。

## 触发词

- `.img` / `.E01` / `.vmdk` / `.raw` 大体积附件
- "攻击者 IP""登录时间""被删的文件""注册表/计划任务"（问答形式）
- `.pcap` 但问"谁连过/传了什么"、`auth.log` / `syslog` / Windows 事件日志

## 能力边界

- 纯"找 hidden flag"附件题 → 去 `misc.md`（取证题一定是"问答"形式）。
- 实时应急响应处置（封 IP/下线业务）→ 按比赛规则来，本 skill 只讲取证分析。

## 识别特征

- 附件是 `.img` / `.E01` / `.vmdk` / `.raw` 且体积大（几百 MB 以上）→ 磁盘/内存取证。
- 题目问"攻击者 IP""登录时间""被删除的文件""注册表/计划任务" → 取证问答。
- `.pcap` 但问的是"谁连过""传了什么文件"（而不是找 hidden flag）→ 取证式流量分析。
- 给了 `auth.log` / `syslog` / Windows 事件日志 → 日志取证。

## 解题检查清单（按顺序走）

1. **先只读挂载/只读打开**：镜像 `mount -o ro,loop` 或用取证工具只读解析。**绝不在原镜像上写**（先 `cp` 一份工作副本）。
2. **时间线**：先拉时间线再看细节——`fls -r` 列文件（含删除标记）、`mactime` 生成时间线。攻击行为在时间线上是"扎堆的异常"。
3. **问什么找什么**（取证题都是问答题）：
   - 攻击者 IP → 日志里的登录失败/成功序列（`auth.log` 的 Failed/Accepted）、流量包的异常外连。
   - 被删文件 → `fls` 找删除标记，`icat` 提取；不行就 `strings` 全扫 + `grep` 关键词。
   - 持久化 → 计划任务（cron/systemd）、启动项、注册表 Run 键。
4. **内存 dump**：`volatility` 先 `imageinfo` 定 profile，再 `pslist`（可疑进程）、`netscan`（网络连接）、`filescan + dumpfiles`（捞文件）。
5. **流量包（取证视角）**：`统计 → 会话` 看"谁跟谁说话最多"；`导出对象 → HTTP/SMB` 捞传输的文件；DNS 查询记录看隧道/外连域名。
6. **交叉验证**：同一结论至少两个来源对上（如日志 IP + 流量的 IP 一致），再写答案。
> **防幻觉铁律**：数字、偏移、密钥、地址、flag 只写工具输出或文件里实际出现的值。

## 常用工具

| 工具 | 用来干什么 | 一句话用法 |
| --- | --- | --- |
| sleuthkit (fls/icat/mactime) | 磁盘镜像分析 | `fls -r -d 镜像` 找删除文件 |
| volatility3 | 内存取证 | `vol -f dump.raw windows.pslist` |
| Wireshark / tshark | 流量取证 | 会话统计找异常外连，导出对象捞文件 |
| strings / grep | 兜底 | 全扫关键词，取证题 30% 靠这个出货 |

## 常见坑

- 坑 1：直接在原镜像上操作 → 写坏了证据就没了。先复制，挂载加 `ro`。
- 坑 2：上来就逐字节看 → 先拉时间线/问答清单，取证是"带着问题找"，不是"地毯式看"。
- 坑 3：volatility profile 选错 → `imageinfo` 先跑，profile 不对后面全错。
- 坑 4：图片隐写题误判成取证 → 纯"找 hidden flag"附件题回 `misc.md`，取证题一定是"问答"形式。
