import Foundation

enum TaskStore {
    static func load() -> TaskStoreData {
        let url = ConfigManager.tasksFileURL
        guard let data = try? Data(contentsOf: url) else { return TaskStoreData() }
        return (try? JSONDecoder().decode(TaskStoreData.self, from: data)) ?? TaskStoreData()
    }

    static func save(_ data: TaskStoreData) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(data) else { return }
        try? data.write(to: ConfigManager.tasksFileURL)
    }

    static func addTask(_ task: TaskItem) {
        var store = load()
        store.tasks.append(task)
        save(store)
    }

    static func deleteTask(id: String) {
        var store = load()
        store.tasks.removeAll { $0.id == id }
        save(store)
    }

    static func listTasks() -> [TaskItem] {
        load().tasks
    }

    static func cleanExpiredTasks() {
        var store = load()
        let now = Date()

        store.tasks.removeAll { task in
            switch task.status {
            case .dismissed, .completed:
                return true
            case .presented:
                guard let dueDate = parseISODate(task.dueAt) else { return false }
                return dueDate <= now
            case .pending:
                return false
            }
        }
        save(store)
    }

    static func updateTaskStatus(id: String, status: TaskStatus) {
        var store = load()
        guard let index = store.tasks.firstIndex(where: { $0.id == id }) else { return }
        store.tasks[index].status = status
        save(store)
    }

    static func updateTaskResponse(id: String, response: String) {
        var store = load()
        guard let index = store.tasks.firstIndex(where: { $0.id == id }) else { return }
        store.tasks[index].response = response
        save(store)
    }

    static func updateLastTriggered(id: String, at: Date) {
        var store = load()
        guard let index = store.tasks.firstIndex(where: { $0.id == id }) else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        store.tasks[index].lastTriggeredAt = formatter.string(from: at)
        save(store)
    }

    static func findDueOnceTasks(now: Date) -> [TaskItem] {
        let store = load()

        return store.tasks
            .filter { $0.status == .pending }
            .compactMap { task -> (TaskItem, Date)? in
                guard let dueDate = parseISODate(task.dueAt) else { return nil }
                return (task, dueDate)
            }
            .filter { $0.1 <= now }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }

    static func parseISODate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }
}
