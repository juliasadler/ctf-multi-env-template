# Crypto

> 适用题型：给一串看不懂的密文 / 一个加密脚本 / 一组 RSA 参数的题。
> 前置：会用 CyberChef，会跑 Python。

## 识别特征

- 纯字母+数字、结尾有 `=` → Base64 家族（先 `base64 -d` 试，再试 base32/16）。
- 字母移位感（`khoor` 这种）→ Caesar，直接爆破 26 种。
- 给了 `n e c` 三个大数 → RSA。
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
