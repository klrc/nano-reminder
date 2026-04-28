import Foundation

enum CLICommand {
    case add(dueAt: String, text: String, shake: Bool, mood: ReminderMood?, choices: [String])
    case list
    case delete(id: String)
    case clean

    static func parse(arguments: [String]) throws -> CLICommand {
        guard let subcommand = arguments.first else {
            throw CLIError.usage("用法: nano-reminder <add|list|delete|clean> [options]")
        }

        switch subcommand {
        case "add":
            return try parseAdd(arguments: Array(arguments.dropFirst()))
        case "list":
            return .list
        case "delete":
            guard let id = arguments.dropFirst().first else {
                throw CLIError.usage("用法: nano-reminder delete <id>")
            }
            return .delete(id: id)
        case "clean":
            return .clean
        default:
            throw CLIError.usage("未知子命令: \(subcommand)")
        }
    }

    private static func parseAdd(arguments: [String]) throws -> CLICommand {
        var dueAt: String?
        var text: String?
        var shake = false
        var mood: ReminderMood?
        var choices: [String] = []

        var i = 0
        while i < arguments.count {
            switch arguments[i] {
            case "--at":
                guard i + 1 < arguments.count else {
                    throw CLIError.missingValue("--at 需要 ISO-8601 时间")
                }
                i += 1
                dueAt = arguments[i]
            case "--text":
                guard i + 1 < arguments.count else {
                    throw CLIError.missingValue("--text 需要提醒内容")
                }
                i += 1
                text = arguments[i]
            case "--shake":
                shake = true
            case "--mood":
                guard i + 1 < arguments.count else {
                    throw CLIError.missingValue("--mood 需要取值: \(ReminderMood.usageList)")
                }
                i += 1
                guard let parsedMood = ReminderMood(rawValue: arguments[i]) else {
                    throw CLIError.badValue("--mood 必须是: \(ReminderMood.usageList)")
                }
                mood = parsedMood
            case "--choices":
                guard i + 1 < arguments.count else {
                    throw CLIError.missingValue("--choices 需要逗号分隔选项")
                }
                i += 1
                choices = arguments[i]
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            default:
                throw CLIError.unknownFlag(arguments[i])
            }
            i += 1
        }

        guard let dueAt else {
            throw CLIError.missingValue("--at 是必填参数")
        }
        guard TaskStore.parseISODate(dueAt) != nil else {
            throw CLIError.badValue("--at 必须是 ISO-8601 时间，例如 2026-04-28T18:00:00+08:00")
        }
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CLIError.missingValue("--text 是必填参数")
        }

        return .add(dueAt: dueAt, text: text, shake: shake, mood: mood, choices: choices)
    }

    func execute() throws -> String {
        switch self {
        case .add(let dueAt, let text, let shake, let mood, let choices):
            return executeAdd(dueAt: dueAt, text: text, shake: shake, mood: mood, choices: choices)
        case .list:
            return executeList()
        case .delete(let id):
            return try executeDelete(id: id)
        case .clean:
            return executeClean()
        }
    }

    private func executeAdd(dueAt: String, text: String, shake: Bool, mood: ReminderMood?, choices: [String]) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let storedText = ReminderText.encode(text, shake: shake, mood: mood)

        let task = TaskItem(
            id: UUID().uuidString,
            text: storedText,
            choices: choices.isEmpty ? nil : choices,
            response: nil,
            createdAt: formatter.string(from: Date()),
            dueAt: dueAt,
            status: .pending,
            lastTriggeredAt: nil
        )

        TaskStore.addTask(task)
        return "已添加提醒: \(text) (到期: \(dueAt))"
    }

    private func executeList() -> String {
        let tasks = TaskStore.listTasks()
        if tasks.isEmpty {
            return "暂无提醒"
        }

        var lines: [String] = []
        lines.append("ID       状态       时间                          内容")
        lines.append(String(repeating: "-", count: 86))

        for task in tasks {
            let shortId = String(task.id.prefix(8))
            let statusStr = task.status.rawValue
            lines.append("\(shortId)   \(statusStr.padding(toLength: 10, withPad: " ", startingAt: 0))\(task.dueAt.padding(toLength: 30, withPad: " ", startingAt: 0)) \(task.text)")
        }

        return lines.joined(separator: "\n")
    }

    private func executeDelete(id: String) throws -> String {
        var store = TaskStore.load()
        let foundExact = store.tasks.firstIndex(where: { $0.id == id })
        let foundPrefix = store.tasks.firstIndex(where: { $0.id.hasPrefix(id) })

        guard let index = foundExact ?? foundPrefix else {
            throw CLIError.notFound("未找到 ID 为 \(id) 的提醒")
        }

        store.tasks.remove(at: index)
        TaskStore.save(store)
        return "已删除提醒: \(id)"
    }

    private func executeClean() -> String {
        let before = TaskStore.load().tasks.count
        TaskStore.cleanExpiredTasks()
        let after = TaskStore.load().tasks.count
        let cleaned = before - after
        return cleaned > 0 ? "已清理 \(cleaned) 个过期提醒" : "没有需要清理的提醒"
    }
}

enum CLIError: Error, LocalizedError {
    case usage(String)
    case missingValue(String)
    case badValue(String)
    case unknownFlag(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .usage(let msg): return msg
        case .missingValue(let msg): return msg
        case .badValue(let msg): return msg
        case .unknownFlag(let msg): return "未知参数: \(msg)"
        case .notFound(let msg): return msg
        }
    }
}
