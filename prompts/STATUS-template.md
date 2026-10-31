# STATUS.md · 状态卡模板

> 来源：《AI+CTF，我是如何用本地大模型拿下山东省赛冠军的？》§4"状态管理"、§7 第 1/4 条。
> 用法：每道题一个工作目录 `{{workspace}}/{{category}}/{{slug}}/`，目录里放一份本文件。
> 规则：所有状态只写进这张卡，不靠 Agent 记忆；续作先读本卡，从 `next` 继续；多环境并行时这张卡就是共享事实源。

```markdown
# STATUS · {{category}}/{{slug}}

## category
<!-- 填写说明：题型分诊结论，只能填一个主入口：web / pwn / crypto / reverse / misc / forensics / malware / osint / ai-ml。拿不准时填"待定"，10 分钟内必须定下来。 -->
web

## flag
<!-- 填写说明：题面要求的 flag 格式，如 flag{...}。还没解出填"未得"。注意：这里只写格式要求，不写猜测的 flag 值。 -->
flag{...}

## hypothesis
<!-- 填写说明：当前主假设 + 证伪条件，一句话。每次换假设就改写这一行，旧假设移到 facts 标注"已证伪"。 -->
主假设：登录框存在 SQL 注入；证伪条件：单引号测试无报错回显且延时无变化。

## facts
<!-- 填写说明：已证实的事实，一行一条，只写工具实际输出或文件里出现的值（防幻觉铁律）。
     格式：- {{事实}}（{{怎么证实的}}）
     失败的实验也要记，标注"已证伪"，不再重跑。 -->
- 目标开放 80/8080 端口（nmap 实测）
- /login 接口单引号返回 500（curl 实测）——已证伪"无注入点"

## next
<!-- 填写说明：下一步只写一个实验：做什么 + 验证哪个假设。不许写两个。 -->
用 sqlmap 跑 /login 的 POST 参数，验证"布尔盲注可行"假设。
```

## 字段与现有 triage.md 的对应关系

| STATUS.md 字段 | triage.md 对应概念 | 说明 |
|---|---|---|
| facts | Fact | 已证实的客观发现，一一对应 |
| hypothesis | Intent | 下一步要试的方向；STATUS 版要求同时写清证伪条件 |
| （facts 标注"已证伪"） | DeadEnd | 证实走不通的路；STATUS 版不另设字段，直接在 facts 里标注 |
| next | — | triage.md 无固定字段，STATUS 版新增：永远只保留一个下一步 |
| category / flag | — | triage.md 分诊表/第 1 步"设定起点与目标"的结构化落点 |

（上表为 STATUS 字段与 triage.md 概念的完整对应关系。）
