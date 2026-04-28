# Nano Reminder

macOS 菜单栏提醒壳子：常驻进程负责弹窗，命令行负责写入提醒或立即显示窗口。

## 特性

- 状态栏常驻，无独立主窗口
- 一次性定时提醒
- 立即显示提醒窗口
- 自适应气泡宽高，支持 `**strong**`、`*emphasis*`、`` `code` `` 等 Markdown inline 渲染
- 可选按钮提示，支持轻量 yes/no/custom ask 流程
- CLI 子命令：`add` / `show` / `list` / `delete` / `clean`
- 数据持久化至 `~/Library/Application Support/nano-reminder/tasks.json`
- 到点弹出左下角悬浮气泡

## 运行

### 常驻模式

```bash
cd /Users/sh/Code/nano-reminder/NanoReminder
swift run -- --resident
```

### 立即弹出窗口

```bash
bin/nano-reminder show --text "现在喝水"
bin/nano-reminder show --text "**构建完成**，可以回来啦" --mood happy
bin/nano-reminder show --text "支持 `code`、*强调* 和 **重点**" --mood happy
bin/nano-reminder show --text "要继续吗？" --mood confused --choices "继续,取消"
bin/nano-reminder show --text "马上回来处理这个失败" --shake --mood panic
```

支持表情：`calm` / `happy` / `grateful` / `confused` / `panic` / `shocked`。

### 添加定时提醒

```bash
bin/nano-reminder add --at "2026-04-28T18:00:00+08:00" --text "下班打卡"
```

## 给自动化工具的最小接口

```bash
# 立刻弹出
/Users/sh/Code/nano-reminder/bin/nano-reminder show --text "提醒内容"
/Users/sh/Code/nano-reminder/bin/nano-reminder show --text "构建完成" --mood happy

# 写入一个未来提醒；常驻进程到点弹出
/Users/sh/Code/nano-reminder/bin/nano-reminder add --at "2026-04-28T18:00:00+08:00" --text "提醒内容"
```

## Claude Code 集成

项目根目录提供 `.mcp.json`，Claude Code 在 `/Users/sh/Code/nano-reminder` 中运行时会自动发现 `nano-reminder` MCP server。

可用工具：

- `notify_now`：立即弹出提醒窗口
- `schedule_reminder`：写入一个未来的一次性提醒

`CLAUDE.md` 已约定：当用户说“完成后通知我”“最后通知我”“弄完提醒我”等表达时，Claude 应在任务完成后调用 `notify_now`。

示例：

```text
你帮我检查一下构建是否通过，最后通知我。
```

也可以安装用户级 Stop hook，让所有 Claude Code 对话结束时自动把最终回复镜像成 Nano 弹窗，不依赖 MCP：

```bash
bin/install-claude-hook.sh
bin/uninstall-claude-hook.sh
```

hook 会读取最终回复末尾的 `<!-- nano-mood:happy -->` 这类隐藏标记选择表情，并在已经发过 Nano 通知时跳过，避免重复弹窗。

## CLI

```bash
nano-reminder show --text "现在喝水"
nano-reminder show --text "**构建完成**，可以回来啦" --mood happy
nano-reminder show --text "支持 `code`、*强调* 和 **重点**" --mood happy
nano-reminder show --text "要继续吗？" --mood confused --choices "继续,取消"
nano-reminder show --text "马上回来处理这个失败" --shake --mood panic
nano-reminder add --at "2026-04-28T18:00:00+08:00" --text "下班打卡"
nano-reminder list
nano-reminder delete <id>
nano-reminder clean
```

`delete` 支持 ID 前缀匹配。

`clean` 会清理 `dismissed` / `completed` 状态的提醒，以及已经过期的 `presented` 提醒。

## 数据格式

```json
{
  "version": 3,
  "tasks": [
    {
      "id": "uuid",
      "text": "下班打卡",
      "createdAt": "2026-04-28T14:00:00Z",
      "dueAt": "2026-04-28T18:00:00+08:00",
      "status": "pending",
      "lastTriggeredAt": null
    }
  ]
}
```

`status`：`pending` -> `presented` -> `dismissed`

## 架构

```text
NanoReminder
├── CLI
│   ├── show --text ...
│   ├── add --at ... --text ...
│   ├── list
│   ├── delete <id>
│   └── clean
│
├── Backend
│   ├── ConfigManager: ~/Library/Application Support/nano-reminder/
│   ├── TaskStore: JSON 持久化 + CRUD
│   └── TaskScheduler: 1s 轮询调度
│
└── Frontend
    ├── StatusItem: 菜单栏 "乃" 图标 + 菜单
    ├── ReminderWindow: 左下角通知气泡
    └── ReminderViewModel: 动画 + 展示逻辑
```
