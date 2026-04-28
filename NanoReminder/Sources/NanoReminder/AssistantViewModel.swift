import Foundation
import SwiftUI

@MainActor
final class AssistantViewModel: ObservableObject {
    @Published var reminderText = ""
    @Published var isPresented = false
    @Published var isFloating = false

    var currentReminderID: String?
    var onDismiss: ((String?) -> Void)?

    func present(text: String, reminderID: String?) {
        reminderText = text
        currentReminderID = reminderID
        isFloating = false

        withAnimation(.spring(response: 0.58, dampingFraction: 0.82)) {
            isPresented = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                self.isFloating = true
            }
        }
    }

    func dismiss() {
        let reminderID = currentReminderID
        withAnimation(.easeInOut(duration: 0.2)) {
            isPresented = false
        }
        isFloating = false
        currentReminderID = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self] in
            self?.onDismiss?(reminderID)
        }
    }
}
