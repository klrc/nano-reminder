import Foundation

enum TaskStatus: String, Codable {
    case pending
    case presented
    case dismissed
    case completed
}

struct TaskItem: Codable, Identifiable, Hashable {
    let id: String
    let text: String
    var choices: [String]?
    var response: String?
    let createdAt: String
    var dueAt: String
    var status: TaskStatus
    var lastTriggeredAt: String?
}

struct TaskStoreData: Codable {
    var version: Int = 3
    var tasks: [TaskItem] = []
}
