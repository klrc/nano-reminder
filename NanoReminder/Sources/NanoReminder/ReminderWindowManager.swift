import AppKit
import SwiftUI

@MainActor
final class ReminderWindowManager {
    private var windows: [String: AssistantWindow] = [:]
    private var viewModels: [String: AssistantViewModel] = [:]
    private var tasks: [String: TaskItem] = [:]
    private var onDismiss: ((TaskItem) -> Void)?

    func setOnDismiss(_ handler: @escaping (TaskItem) -> Void) {
        onDismiss = handler
    }

    func present(task: TaskItem) {
        print("ReminderWindowManager present \(task.id) \(task.text)")
        let windowSize = calculateWindowSize(text: task.text)

        let viewModel = AssistantViewModel()
        viewModel.onDismiss = { [weak self] _ in
            guard let self else { return }
            self.onDismiss?(task)
            self.dismiss(task: task)
        }

        let rootView = AssistantRootView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: rootView.frame(width: windowSize.width, height: windowSize.height))

        let idx = windows.count
        let window = AssistantWindow(
            contentRect: calculateWindowFrame(index: idx, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        let taskID = task.id
        windows[taskID] = window
        viewModels[taskID] = viewModel
        tasks[taskID] = task

        viewModel.present(text: task.text, reminderID: task.id)
    }

    func dismiss(task: TaskItem) {
        let taskID = task.id
        guard let window = windows[taskID] else { return }
        window.orderOut(nil)
        windows.removeValue(forKey: taskID)
        viewModels.removeValue(forKey: taskID)
        tasks.removeValue(forKey: taskID)
        repositionAllWindows()
    }

    private func calculateWindowFrame(index: Int, size: NSSize) -> NSRect {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let gap: CGFloat = 18
        let x = visibleFrame.minX + gap
        let y = visibleFrame.minY + gap + CGFloat(index) * (size.height + gap)
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    private func calculateWindowSize(text: String) -> NSSize {
        let width: CGFloat = 660
        let minHeight: CGFloat = 128
        let maxHeight = max(minHeight, (NSScreen.main?.visibleFrame.height ?? 900) - 80)
        let textWidth: CGFloat = 510
        let font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        let bounds = (text as NSString).boundingRect(
            with: NSSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        let chromeHeight: CGFloat = 92
        let height = min(max(minHeight, ceil(bounds.height) + chromeHeight), maxHeight)
        return NSSize(width: width, height: height)
    }

    private func repositionAllWindows() {
        let orderedKeys = windows.keys.sorted { a, b in
            let windowA = windows[a]!
            let windowB = windows[b]!
            return windowA.frame.minY < windowB.frame.minY
        }
        for (index, key) in orderedKeys.enumerated() {
            guard let window = windows[key] else { continue }
            window.setFrame(calculateWindowFrame(index: index, size: window.frame.size), display: true, animate: true)
        }
    }
}
