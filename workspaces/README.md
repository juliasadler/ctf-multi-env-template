# 工作目录说明

## 结构

```
workspaces/<环境ID>/
├── IDENTITY.md                 # 身份卡：环境 ID、角色、主机、工作目录路径、tmux 会话
├── challenges/<题目编号>/      # 每题一个目录：工作副本 + 过程文档.md + 解题文件
├── logs/                       # tmux 日志：tmux-ctf-<环境ID>.log
└── notes.md                    # 杂记（不放 flag）
```

## 规则

- 一环境一目录，目录名就是环境 ID，不共用。
- 只写自己的目录，不写别人的目录，不改共享 `challenges/` 原题。
- 每题目录里必须有 `过程文档.md`，按 `../templates/过程文档模板.md` 写。
- 解题操作都在 `ctf-<环境ID>` 这个 tmux 会话里做，日志落到自己 `logs/` 里。
