import Foundation
import SwiftUI

@MainActor
final class AssistantViewModel: ObservableObject {
    @Published var reminderText = ""
    @Published var mood: ReminderMood = .defaultMood
    @Published var isPresented = false
    @Published var isFloating = false
    @Published var shakePhase: CGFloat = 0

    var currentReminderID: String?
    var onDismiss: ((String?) -> Void)?

    func present(text: String, reminderID: String?) {
        let content = ReminderText.content(from: text)
        reminderText = content.displayText
        mood = content.mood
        currentReminderID = reminderID
        isFloating = false

        withAnimation(.spring(response: 0.58, dampingFraction: 0.82)) {
            isPresented = true
        }

        if content.shouldShake {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
                guard let self else { return }
                withAnimation(.linear(duration: 0.46)) {
                    self.shakePhase += 1
                }
            }
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
        shakePhase = 0
        currentReminderID = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self] in
            self?.onDismiss?(reminderID)
        }
    }
}
