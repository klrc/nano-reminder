import Foundation

enum CLIOutput {
    static func printError(_ message: String) {
        fputs("✗ \(message)\n", stderr)
    }

    static func printUsage() {
        print("""
        Nano Reminder - macOS reminder shell

        用法:
          nano-reminder add --at <ISO-8601 时间> --text <内容> [--shake] [--mood \(ReminderMood.usageList)] [--choices 是,否]
          nano-reminder show --text <内容> [--shake] [--mood \(ReminderMood.usageList)] [--choices 是,否]
          nano-reminder list
          nano-reminder delete <id>
          nano-reminder clean
          nano-reminder --resident

        示例:
          nano-reminder add --at "2026-04-28T18:00:00+08:00" --text "下班打卡"
          nano-reminder show --text "构建完成" --mood happy
        """)
    }
}
