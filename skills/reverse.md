---
name: reverse
description: Reverse 题解题方法：静态分析→反编译→数据流追踪→复刻解密
triggers: ["二进制", "要求输入", "stripped", "UPX", ".wasm", "Go二进制", "反调试", "逆出flag"]
题型: Reverse
# 预留：当前 skill 文件少，frontmatter 供未来路由/检索用，暂不做自动路由
---

# Reverse

> 适用题型：给一个二进制（ELF/PE），让你逆出 flag 或输入正确的 key。
> 前置：会看汇编大意，会用 Ghidra/IDA 基础操作，会写 Python。

## 前置工具（Prerequisites）

- Ghidra（或 IDA）：反编译（Ghidra 免费，赛前装好，重型）。
- checksec：看保护/是否 stripped（pwntools 自带）。
- gdb + pwndbg：动调（比较处下断看寄存器）。
- Python：复刻解密脚本。

## 触发词

- 给了二进制，要求输入正确内容 / 逆出 flag
- `file` 显示 stripped、UPX 加壳（strings 全乱码）
- `.wasm` 附件、Go 二进制（`go.buildid`）、反调试（ptrace）、VM 题

## 能力边界

- 拿 shell 的 pwn 利用 → 逆向只到"理解逻辑"，写 exp 去 `pwn.md`。
- 问行为/IoC 的可疑样本 → 去 `malware.md`；纯动态分析 → 用 gdb/沙箱，不在本 skill 展开。

## 识别特征

- 无窗口、一运行就要求输入 → 逆向无疑。
- `file` 显示 stripped → 符号被剥了，靠字符串和交叉引用定位。
- UPX 加壳（`strings` 全是乱码）→ 先脱壳再分析。
- 附件是 `.wasm` → WASM 逆向（看导出函数）。
- 二进制巨小但行为复杂 / 字符串里有虚拟机字样 → 可能是 VM 题（先找 opcode 分发表）。
- Go 写的二进制（`strings` 有 `go.buildid`）→ 用 GoReSym 恢复符号。

## 解题检查清单（按顺序走）

1. **`file` + `checksec` + `strings`**：先看架构、位数、有没有壳。`strings | grep -i flag` 经常有惊喜（出题人留的提示语）。
2. **脱壳**：UPX → `upx -d`。脱完重跑 `file` 确认。
3. **扔进 Ghidra 反编译**：找 `main`，顺着输入往下读。重点看：比较函数（`strcmp`/`memcmp`）、加密循环（异或 `^`、换表、位移）。
4. **定位关键逻辑**：输入经过哪几步变换、最后和哪个常量比较。把变换抄出来——90% 的逆向题到这一步就结束了：反着写 Python 解密。
5. **数据流追踪（source→sink）**：标出输入源（argv/文件/网络读入）→ 经过的变换 → 最终校验点（sink，如 `memcmp`/`strcmp` 比较处）。
   把"输入→变换→比较"这条链画出来再反写解密——这是逆向的固定分析框架，比逐行读代码快，且变换链就是解密脚本的骨架。
6. **常见魔改**：单字节异或（爆破 0-255）、换表（找表）、RC4（找 S 盒初始化）、base64 变表（找那 64 个字符）。
7. **实在读不懂**：动调（`gdb` 下断点在比较处，看寄存器里的值），或对拍——改输入看输出怎么变，反推变换。
8. **特殊题型入口**：`.wasm` → `wasm-objdump` 看导出函数再决定；反调试（`ptrace`/`IsDebuggerPresent`）→ 先 patch 掉再动调；
   Go 二进制 → `GoReSym` 恢复函数名再看；VM 题 → 先找 opcode 分发表，一条条翻译。
> **防幻觉铁律**：数字、偏移、密钥、地址、flag 只写工具输出或文件里实际出现的值。

## 常用工具

| 工具 | 用来干什么 | 一句话用法 |
| --- | --- | --- |
| Ghidra / IDA（含 MCP 形态） | 反编译 | 人用：找 main，跟输入走；Agent：IDA-MCP 直调反编译/交叉引用（需手动在 IDA Pro 配 MCP 插件并注册，文章 §6） |
| checksec | 看保护 | 逆向主要看是不是 stripped |
| gdb (+pwndbg) | 动调 | 比较处下断，看寄存器 |
| Python | 复刻解密 | 把加密抄下来反着写，样例验证 |
| Jadx-MCP | Agent 调 Jadx 反编译（Android/Java） | 先请用户打开 Jadx，确认后再调；需手动配置 MCP（文章 §6） |
| x64dbg-MCP | Agent 调 x64dbg 动调（Windows PE） | 先请用户打开 x64dbg，确认后再调；需手动配置 MCP（文章 §6） |

## 常见坑

- 坑 1：在汇编里死磕 → 先看反编译伪代码，伪代码看不懂才回汇编。
- 坑 2：异或密钥猜不出来 → 0-255 爆破，可打印字符大概率就是答案。
- 坑 3：脱壳后还用加壳前的地址 → 脱壳完重新载入分析，别混。
