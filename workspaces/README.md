# 工作目录说明

## 结构

```
workspaces/<环境ID>/
├── IDENTITY.md                 # 身份卡：环境 ID、角色、主机、工作目录路径、tmux 会话
├── challenges/<题目编号>/      # 每题一个目录：工作副本 + 过程文档.md + 解题文件
├── logs/                       # tmux 日志：一题一日志 tmux-ctf-<环境ID>-<题目编号>.log
└── notes.md                    # 杂记（不放 flag）
```

## 规则

- 一环境一目录，目录名就是环境 ID，不共用。
- 只写自己的目录，不写别人的目录，不改共享 `challenges/` 原题。
- 每题目录里必须有 `过程文档.md`，按 `../templates/过程文档模板.md` 写。
- **一题一会话**：所有解题操作在 `ctf-<环境ID>-<题目编号>` 会话里做（起会话：`scripts/start-tmux.sh <环境ID> <题目编号>`），日志为一题一日志 `logs/tmux-ctf-<环境ID>-<题目编号>.log`（start-tmux.sh 已自动开 pipe-pane）。旧的 `ctf-<环境ID>` 单会话口径已废弃，残留旧会话手动 `tmux kill-session -t ctf-<环境ID>` 清理，日志文件保留备查。
- 过程文档里必须写 tmux 会话名和日志路径，方便按日志复现。详情见《协议与约束.md》第 7 条。
