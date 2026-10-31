---
name: misc
description: MISC 题解题方法：找 hidden flag——图片/音频隐写、压缩包、二维码、编码、jail
triggers: ["图片附件", "zip密码", "二维码", "频谱", "pyjail", "binwalk", "hidden flag"]
题型: MISC
# 预留：当前 skill 文件少，frontmatter 供未来路由/检索用，暂不做自动路由
---

# MISC

> 适用题型：给一个附件（图片/音频/压缩包），让你"找 hidden flag"。
> 前置：会用 `file`、`binwalk`，会看 16 进制（`xxd`）。
> 注意：流量包取证（"攻击者是谁/传了什么"类问答）归 `forensics.md`，这里只讲"找 hidden flag"视角。

## 前置工具（Prerequisites）

- binwalk：分离附加文件（`apt install binwalk`）。
- zsteg / steghide：图片隐写（`gem install zsteg` / `apt install steghide`）。
- Audacity：音频频谱（看 SSTV/摩斯）。
- fcrackzip：压缩包爆破（真加密且明文攻击失败后用）。
- 按需安装；`file` / `strings` / `xxd` 系统自带。

## 触发词

- 图片/音频/压缩包附件，"找 hidden flag"
- 图片打不开/体积异常、`.zip` 要密码、二维码扫不出
- 只能输 Python 的框（jail）、`.pcap` 但只找 hidden flag

## 能力边界

- 取证问答（"攻击者是谁""被删文件内容"）→ 去 `forensics.md`。
- 流量包问答式分析 → 去 `forensics.md` 第 5 步；这里只讲"找 hidden flag"视角。

## 识别特征

- 图片打不开 / 体积异常大 → 隐写或附加数据。
- `.pcap/.pcapng` 但只找 hidden flag → 先看本清单第 4 步；问答式取证去 `forensics.md`。
- `.zip` 打不开 / 要密码 → 伪加密或爆破。
- 二维码扫不出来 → 补定位角或反色。

## 解题检查清单（按顺序走）

1. **`file` + `binwalk`**：先看真实类型。`binwalk -e` 直接分离，经常一步出货。`xxd | head` 看文件头尾（PK/JPEG 头、flag 字符串直接 `strings | grep flag`）。
2. **图片隐写**：
   - `zsteg` 跑一遍（PNG 最常用）。
   - `steghide extract -sf` 试空密码和常见密码。
   - 盲水印：`BlindWatermark` 解。
   - 都不是 → 扔进 StegSolve 看各通道/最低位。
3. **音频**：扔进 Audacity 看频谱（SSTV/摩斯藏频谱里很常见）；DTMF 音用 `dtmf-decoder`。
4. **流量包（只找 hidden flag）**：Wireshark `文件 → 导出对象 → HTTP` 一键导出传输过的文件；
   `追踪流` 看可疑会话。问答式取证（谁连过/传了什么）去 `forensics.md` 第 5 步。
5. **压缩包**：
   - 打不开但能列目录 → 伪加密（把标志位改回来）。
   - 真加密 → 先试明文攻击（找同名已知文件），再爆破（`fcrackzip`/`ARCHPR`）。
   - CRC32 已知 → 反推 4 字节以内原文。
6. **二维码**：扫不出来先反色、补齐三个定位角，不行就 `zbarimg`。
7. **Python/Bash Jail（沙箱逃逸入门）**：给个只能输 Python 的框 → 先试能用什么（`().__class__`、`().__class__.__bases__` 探路）；
   被禁关键字 → 换写法绕（字符串拼接、getattr）；目标一般是读文件或执行命令，拿到 flag 即停。

## 常用工具

| 工具 | 用来干什么 | 一句话用法 |
| --- | --- | --- |
| binwalk | 分离附加文件 | `binwalk -e 文件` |
| zsteg / steghide | 图片隐写 | `zsteg 图.png`；`steghide extract -sf 图.jpg` |
| Wireshark / tshark | 流量分析 | 先看协议分级，再追踪流、导出对象 |
| CyberChef | 万能转换 | From Hex / Raw Deflate 救急 |

## 常见坑

- 坑 1：上来就 steghide，别的都不看 → 按清单顺序走，`binwalk` 和 `strings` 永远先行。
- 坑 2：流量包一个个点 → 先统计再看，找"异常大/异常多"的流。
- 坑 3：压缩包爆破字典选太大 → 先明文攻击，再短字典，最后才上大字典。
