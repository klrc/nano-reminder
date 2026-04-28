import Foundation

enum DataMigrator {
    static func migrateIfNeeded() {
        let tasksFile = ConfigManager.tasksFileURL
        guard !FileManager.default.fileExists(atPath: tasksFile.path) else { return }
        TaskStore.save(TaskStoreData())
    }
}
