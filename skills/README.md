# skills/ · 题型解题方法沉淀

> 这里放的是**方法论**，不是题解：每个 skill 讲一类题型的"怎么识别、按什么顺序查、用什么工具、哪里容易踩坑"。
> 做题前先读对应 skill，认领后 10 分钟没思路就回来翻一遍检查清单。

## 规矩

1. skill 只写通用方法，不写具体题目的 flag、答案、payload 全文（见《协议与约束.md》第 8 条）。
2. 文件名小写英文，一个题型一个文件：`web.md` / `crypto.md` / `misc.md` / `reverse.md` / `pwn.md`
   / `forensics.md` / `osint.md` / `ai-ml.md` / `malware.md` / `writeup.md`，
   外加两个流程文件：`triage.md`（总入口，先读）、`patterns.md`（模式速查）。
3. 新增 skill：复制 `skill-template.md` 改名，按里面的节填写；"前置工具（Prerequisites）""触发词""能力边界""识别特征""解题检查清单"五节必填（头部三件套 + 两核心），其余节可增删。每个文件头部必须带 YAML frontmatter（`name`/`description`/`triggers`/`题型` 四字段）：当前 skill 文件少，只作元数据预留、供未来路由/检索用，暂不做自动路由。
4. 方法有更新直接改对应 skill，不用记更新日志（记的是模板结构改动）；新增/删除 skill 文件才记一笔。
5. 通用流程（分诊/状态记录/卡住恢复）只写 `triage.md`，题型文件不重复；
   两处沾边的内容按归属表放一处，另一处只留一句话指向（当前：流量包取证归 `forensics.md`，`misc.md` 只留找 flag 视角）。
6. 做题顺序：先 `triage.md` 分诊 → 再读对应题型 skill → 卡住查 `patterns.md`。

## 外部引用（按需用，不吸收进本仓库）

- `/secknowledge`：Web/AI 漏洞 payload 速查（在 `web.md`/`ai-ml.md` 需要 payload 细节时引用）。
- `/pentest-report`：正式 `.docx` 报告生成（仅用户明确要求正式报告时启用，见 `writeup.md`）。
- [ljagiello/ctf-skills](https://github.com/ljagiello/ctf-skills)：上游方法库，按题型分目录的深水参考，定期 diff 跟进。

## 现有 skill

| 文件 | 覆盖 |
| --- | --- |
| `triage.md` | 总入口：分诊表、OODA 解题循环、状态记录、卡住恢复 |
| `patterns.md` | 跨题型模式速查（特征→模式→去哪）、绕过策略通用原则 |
| `web.md` | SQL 注入、XSS、文件上传、命令注入、SSRF、反序列化、JWT、SSTI、IDOR、源码泄露 |
| `crypto.md` | 古典密码识别、编码套娃、RSA 常见攻击、ECC 入门、PRNG/LCG、AES/ECB、工具链 |
| `misc.md` | 文件类型识别、图片/音频隐写、压缩包、二维码、Python/Bash Jail |
| `reverse.md` | 静态分析流程、反编译、常见加密魔改、WASM、反调试、Go 二进制、动调、Python 复刻 |
| `pwn.md` | checksec、栈溢出三件套、格式化字符串、堆入门与进阶、沙箱逃逸、pwntools 模板 |
| `forensics.md` | 磁盘镜像、内存取证、日志分析、取证式流量分析 |
| `osint.md` | 用户名/邮箱、照片定位、域名资产、社媒交叉（只查公开信息） |
| `ai-ml.md` | 提示词注入、越狱、模型文件初探 |
| `malware.md` | 可疑样本静态初判、去混淆、C2 定位、沙箱动态验证（隔离执行） |
| `writeup.md` | 赛后 Writeup 结构、脱敏自查 |
