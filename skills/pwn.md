# Pwn

> 适用题型：给一个二进制 + 一个远程地址（`nc ip port`），让你拿 shell 或读 flag。
> 前置：会 Reverse 基础流程，会 Python，会用 pwntools。

## 识别特征

- 题目给 `nc` 地址 → 99% 是 pwn。
- `checksec` 显示 NX/PIE/Canary 开了几个 → 决定打法难度。
- 菜单题（1.XX 2.XX）→ 堆题概率大，先别碰栈溢出那套。

## 解题检查清单（按顺序走）

1. **`checksec --file=`**：Canary 开了就别想简单栈溢出了；NX 没开 → ret2shellcode；PIE 没开 → 地址固定，好打。
2. **本地复现**：先本地跑通，再打远程。`pwn template` 生成 exp 骨架。
3. **栈溢出三件套**（按保护从弱到强）：
   - ret2text：有后门函数（`system("/bin/sh")` 之类）直接跳。
   - ret2shellcode：NX 没开，shellcode 写进 buf 跳过去。
   - ret2libc：先泄露 libc 地址（`puts`/`write` 打印 got 表），算出 `system` 地址，再 `system("/bin/sh")`。
4. **格式化字符串**：看到 `printf(buf)`（用户输入直接当格式串）→ 先用 `%p` 泄露栈/ libc 地址，再 `%n` 写内存。
5. **堆题（入门）**：先搞懂 UAF（释放后还用）→ 劫持 `free@got` 为 `system`，`free("/bin/sh")` 拿 shell。堆题先画堆块图，别凭空想。
6. **打远程**：本地通了，把 `process` 换 `remote(ip, port)`，地址/偏移用远程泄露的重新算一遍（本地 libc 和远程可能不一样）。

## 常用工具

| 工具 | 用来干什么 | 一句话用法 |
| --- | --- | --- |
| checksec | 看保护机制 | `checksec --file=./pwn` |
| pwntools | 写 exp | `pwn template` 生成骨架，`elf/gdb/remote` 一条龙 |
| ROPgadget | 找 gadget | `ROPgadget --binary ./pwn \| grep "pop rdi"` |
| pwndbg | 动调 | `cyclic` 算偏移，断点看栈 |

## 常见坑

- 坑 1：本地通了远程不通 → 九成是 libc 版本/偏移不对，用远程泄露的地址重算。
- 坑 2：`cyclic` 找的偏移直接用 → 确认位数（32/64）和填充，别差 8 字节。
- 坑 3：菜单堆题上来就 exp → 先手动玩几轮菜单，把堆块变化画出来再写脚本。
