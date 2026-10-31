---
name: crypto
description: Crypto 题解题方法：古典密码/编码套娃/RSA/AES/PRNG/ECC 入门的识别与检查清单
triggers: ["密文", "n e c", "RSA", "base64", "srand", "加密脚本", "椭圆曲线", "AES-ECB"]
题型: Crypto
# 预留：当前 skill 文件少，frontmatter 供未来路由/检索用，暂不做自动路由
---

# Crypto

> 适用题型：给一串看不懂的密文 / 一个加密脚本 / 一组 RSA 参数的题。
> 前置：会用 CyberChef，会跑 Python。

## 前置工具（Prerequisites）

- CyberChef：编码识别+转换（网页版即可，无安装成本）。
- Python + sympy：大数运算（开方/GCD/模逆）。
- RsaCtfTool：RSA 自动攻击（`git clone` 即用）。
- sage：重型数论题再用（大而重，按需安装，不预装）。

## 触发词

- 一串看不懂的密文、结尾带 `=` 的 Base64 家族
- `n e c` 三个大数（RSA）、椭圆曲线参数（`p a b G n`）
- 代码里有 `srand` / `rand` / `random`、给了加密 Python 脚本

## 能力边界

- 不讲 Web 漏洞/二进制逆向 → 去 `web.md` / `reverse.md`。
- 格攻击（Coppersmith）深水区只给入口提示，不展开推导；先确认题型再深挖。

## 识别特征

- 纯字母+数字、结尾有 `=` → Base64 家族（先 `base64 -d` 试，再试 base32/16）。
- 字母移位感（`khoor` 这种）→ Caesar，直接爆破 26 种。
- 给了 `n e c` 三个大数 → RSA。
- 给了椭圆曲线参数（`p a b G n`）→ ECC。
- 代码里有 `srand` / `rand` / `random` → 可预测随机数。
- 给了加密 Python 脚本 → 先读脚本，把加密流程反着写一遍解密。

## 解题检查清单（按顺序走）

1. **先分类**：古典（替换/移位/栅栏/猪圈/摩斯）还是现代（RSA/AES）？古典题 5 分钟没思路就去 CyberChef 的 "Magic" 自动识别。
2. **编码套娃**：Base64 解出来还是乱码 → 套娃了，循环解（base64→hex→rot13 常见三连），每次解完 `file` 看一下是不是可读文本。
3. **RSA（重点）**：按顺序查——
   - `n` 很小（< 512 bit）→ 直接分解（factordb / yafu）。
   - 给了多组 `(n, e, c)` 且 n 相同 → 共模攻击（GCD 求 p）。
   - `e` 很小（e=3）且 c < n → 直接开 e 次方根；多组 c 不同 n → Hastad 广播攻击。
   - 给了 `p q` 或 `phi` 或 `d` → 直接公式解。
   - 都不是 → RsaCtfTool 跑一遍自动攻击（`--autopwn`）。
4. **AES**：看到 ECB 模式（相同明文块密文块相同）→ 剪贴攻击；CBC 翻转字节 → 填充预言。
5. **有脚本的题**：把加密函数抄出来，反着写解密函数，用题目给的样例验证（样例能对上，解密就对了）。
6. **随机数题**：看到 `srand(time(0))` → 种子就是时间戳，前后爆破几秒；看到 `random.random()` 输出很多 → MT19937 状态恢复（624 个输出可还原，先找现成脚本）。
7. **ECC/格（入门）**：ECC 给了小参数 → 用 `ecdsa` 库暴力/小子群；格攻击（Coppersmith）→ 先确认是"已知部分 p"的 RSA 变体，再找 Sage 模板，别手推。

## 常用工具

| 工具 | 用来干什么 | 一句话用法 |
| --- | --- | --- |
| CyberChef | 编码识别+转换 | "Magic" 自动猜，Recipe 链式拼 |
| RsaCtfTool | RSA 自动攻击 | `python RsaCtfTool.py --publickey pub.pem --uncipher c.txt --autopwn` |
| factordb | 查 n 分解 | 别人分解过直接抄 p q |
| sage / sympy | 大数运算 | 开方、GCD、模逆 |

## 常见坑

- 坑 1：RSA 里 e 和 phi 不互素就硬算 d → 先 `gcd(e, phi)` 检查，不互素换思路。
- 坑 2：base64 解码报错就放弃 → 试 `base64 -d -i` 忽略非法字符，或先去掉换行。
- 坑 3：脚本题直接猜 → 先把加密流程"翻译"成中文写下来，反推每一步的逆运算。
