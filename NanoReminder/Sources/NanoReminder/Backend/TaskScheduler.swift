import Foundation

@MainActor
final class TaskScheduler {
    private var timer: Timer?
    private let onDueTasks: ([TaskItem]) -> Void
    private var activeTaskIDs: Set<String> = []

    init(onDueTasks: @escaping ([TaskItem]) -> Void) {
        self.onDueTasks = onDueTasks
    }

    func start() {
        print("TaskScheduler start")
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        print("TaskScheduler stopped")
    }

    private func poll() {
        let now = Date()
        let dueOnce = TaskStore.findDueOnceTasks(now: now)
        let allDue = dueOnce

        // Filter out tasks that are already being presented
        let newDue = allDue.filter { !activeTaskIDs.contains($0.id) }
        guard !newDue.isEmpty else { return }

        for task in newDue {
            print("TaskScheduler due task \(task.id) text=\(task.text)")
            activeTaskIDs.insert(task.id)
            TaskStore.updateTaskStatus(id: task.id, status: .presented)
            TaskStore.updateLastTriggered(id: task.id, at: now)
        }

        onDueTasks(newDue)

        // After showing, clean up active IDs
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            for task in newDue {
                self?.activeTaskIDs.remove(task.id)
            }
        }
    }
}
