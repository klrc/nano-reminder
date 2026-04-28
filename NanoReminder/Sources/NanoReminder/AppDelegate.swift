import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let launchConfig: LaunchConfig
    private var statusItem: NSStatusItem?
    private var scheduler: TaskScheduler?
    private let windowManager = ReminderWindowManager()

    init(launchConfig: LaunchConfig) {
        self.launchConfig = launchConfig
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("NanoReminder launch resident=\(launchConfig.isResident)")
        setupStatusItemIfNeeded()
        setupWindowManager()

        if launchConfig.isResident {
            let scheduler = TaskScheduler { [weak self] tasks in
                for task in tasks {
                    self?.windowManager.present(task: task)
                }
            }
            self.scheduler = scheduler
            scheduler.start()
        } else {
            let text = launchConfig.initialMessage ?? "该去刷牙了"
            let testTask = TaskItem(
                id: UUID().uuidString,
                text: text,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                dueAt: ISO8601DateFormatter().string(from: Date()),
                status: .pending,
                lastTriggeredAt: nil
            )
            windowManager.present(task: testTask)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        scheduler?.stop()
    }

    private func setupStatusItemIfNeeded() {
        guard launchConfig.isResident else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "乃"
        item.button?.toolTip = "Nano Reminder"

        let menu = NSMenu()
        menu.addItem(withTitle: "显示测试提醒", action: #selector(showTestReminder), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 Nano Reminder", action: #selector(quitApp), keyEquivalent: "q")
        item.menu = menu

        statusItem = item
    }

    private func setupWindowManager() {
        windowManager.setOnDismiss { [weak self] task in
            TaskStore.updateTaskStatus(id: task.id, status: .dismissed)
            guard let self, self.launchConfig.quitsAfterInitialMessage else { return }
            NSApp.terminate(nil)
        }
    }

    @objc
    private func showTestReminder() {
        let testTask = TaskItem(
            id: UUID().uuidString,
            text: "记得下班打卡",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            dueAt: ISO8601DateFormatter().string(from: Date()),
            status: .pending,
            lastTriggeredAt: nil
        )
        windowManager.present(task: testTask)
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }
}
