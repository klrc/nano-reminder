# Nano Reminder

When the user asks you to do some work and notify them at the end, use the `nano-reminder` MCP tool `notify_now` after the work is complete.

Use `notify_now` for phrases such as:

- "最后通知我"
- "完成后通知我"
- "弄完提醒我"
- "then notify me"
- "let me know when done"

The notification text should be short and concrete, for example:

- "任务完成"
- "检查完成：没有发现问题"
- "构建失败：swift build 报错"

For future timed reminders, use `schedule_reminder` with an ISO-8601 timestamp.
