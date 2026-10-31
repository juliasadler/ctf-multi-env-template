---
name: web
description: Web 题解题方法：SQLi/XSS/上传/SSRF/SSTI/JWT/IDOR/反序列化的识别与检查清单
triggers: ["URL", "IP+端口", "登录框", "SQL报错", "文件上传", "JWT", "{{7*7}}", "SSRF", "?url=", "userId越权", "serialize"]
题型: Web
# 预留：当前 skill 文件少，frontmatter 供未来路由/检索用，暂不做自动路由
---

# Web

> 适用题型：给一个 URL（或 IP+端口）的 Web 题。
> 前置：会看浏览器开发者工具的网络面板，会用 BurpSuite 抓包改包。

## 前置工具（Prerequisites）

- BurpSuite：抓包改包、重放（赛前装好配好代理）。
- sqlmap：自动化注入（`pip install sqlmap` 或 apt）。
- dirsearch / ffuf：目录爆破（`pip install dirsearch`）。
- Python + requests：写脚本跑盲注/批量验证。
- 赛前装好；赛中缺啥装啥，不搞大而全预装。

## 触发词

- 给了 URL / IP+端口，浏览器能打开
- 登录框、搜索框、`id=` 参数、SQL 报错/堆栈回显
- 文件上传（头像/附件）、`{{7*7}}` 回显 49、JWT 三段式
- `?url=` / `?callback=`（SSRF）、`userId` 越权、`serialize` / `__wakeup`

## 能力边界

- 不讲 payload 全文 → 需要 payload 细节时引用 `/secknowledge`，本 skill 只给"测什么、按什么顺序"。
- 二进制/pwn 利用 → 去 `pwn.md`；AI 对话框/越狱题 → 去 `ai-ml.md`。

## 识别特征

- 页面有登录框、搜索框、id= 之类的参数 → 先怀疑注入。
- 有上传头像/附件/头像裁剪功能 → 文件上传。
- 页面回显 ping / 网址预览 / 图片代理 → 命令注入 / SSRF。
- 报错信息直接把 SQL / 堆栈打出来 → 信息泄露，先记下来。
- Cookie/请求头里有三段式 `xxx.yyy.zzz`（JWT）→ 算法混淆检查。
- 输入 `{{7*7}}` 回显 `49` → SSTI（模板注入）。
- 改别人的 id（如 `userId=1001` 改成 `1002`）能看到别人的数据 → IDOR（越权）。

## 解题检查清单（按顺序走）

1. **信息收集**：扫目录（`dirsearch`/`ffuf`）、看 `robots.txt`、`/.git/`、备份文件（`.bak`/`.swp`）、JS 源码里的接口和注释。很多题答案就藏在这里，这一步没做完不碰注入。
2. **SQL 注入**：`'`、`"`, `\` 逐个试，看报错还是回显差异。分三类：
   - 有报错 → 报错注入，直接读。
   - 无报错但页面有差异（有/无数据）→ 布尔盲注，写脚本跑（别手工一个个试）。
   - 无差异 → 时间盲注（`sleep(5)` 验证），或试堆叠注入（`;`）。
   - 工具：`sqlmap -u "URL" --batch --dbs` 先跑一遍，跑不出再手注。WAF 拦截关键字时详见 `patterns.md` 绕过策略章节。
3. **文件上传**：先试正常图片看回显路径，再试 `shell.php` → 被拦则换：`.phtml`/`.php5`/`.htaccess`、MIME 改 `image/png`、文件名双写（`shell.pphphp`）、GIF89a 头 + 一句话木马。上传后找解析路径，蚁剑连。
4. **命令注入 / SSRF**：输入框试 `;id`、`|id`、`$(id)`；SSRF 先打 `http://127.0.0.1:端口` 探内网，再读 `file:///etc/passwd` 验证。
5. **反序列化 / JWT**：看到 `serialize`、`__wakeup`、JWT 三段式，先找源码（第 1 步），有源码再分析 gadget，没有就先放一放。
   JWT 专项：把 `alg` 改成 `none` 试试；试弱密钥爆破（`jwt_tool`）；注意 `kid` 参数（路径穿越读文件）。
6. **SSTI / IDOR**：`{{7*7}}` 回显 49 → 先判模板引擎（报错信息/Jinja2/Twig 特征），再找对应 payload；
   IDOR → 把 id 参数逐个改一遍，看到别人的数据即中，批量验证别手工。
7. **拿 flag 后的动作**：按模板把"入口点→利用链→flag 位置"写进过程文档，别只记 flag。

## 常用工具

| 工具 | 用来干什么 | 一句话用法 |
| --- | --- | --- |
| BurpSuite | 抓包改包、重放 | 浏览器挂代理，所有请求先过一遍 Repeater |
| sqlmap | 自动化注 | `--batch --dbs` 开局，有 WAF 加 `--tamper=space2comment` |
| dirsearch / ffuf | 目录爆破 | `dirsearch -u URL -e php,html,js,txt,bak` |
| 蚁剑 | 连 webshell | 上传成功后 URL+密码连，看回显 |
| jwt_tool | JWT 检查 | `python jwt_tool.py <token>` 先扫算法混淆和弱密钥 |

## 常见坑

- 坑 1：页面"看起来没变化"就断定没注入 → 换时间盲注验证一次，`sleep(5)` 是最便宜的确认。
- 坑 2：sqlmap 跑半天没结果还死磕 → 先手工确认注入点存在，工具只是加速器。
- 坑 3：上传的 shell 404 → 多半是解析路径不对，回去看上传接口的返回 JSON/注释找真实路径。
