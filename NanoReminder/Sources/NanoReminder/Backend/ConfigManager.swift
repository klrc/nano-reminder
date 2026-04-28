import Foundation

enum ConfigManager {
    static var tasksFileURL: URL {
        let manager = FileManager.default
        let appSupportDir = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let nanoAssistDir = appSupportDir.appendingPathComponent("nano-reminder", isDirectory: true)

        if !manager.fileExists(atPath: nanoAssistDir.path) {
            try? manager.createDirectory(at: nanoAssistDir, withIntermediateDirectories: true)
        }

        return nanoAssistDir.appendingPathComponent("tasks.json")
    }
}
