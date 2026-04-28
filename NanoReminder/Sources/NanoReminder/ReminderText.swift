struct ReminderContent {
    let displayText: String
    let shouldShake: Bool
    let mood: ReminderMood
}

enum ReminderText {
    private static let shakeMarker = "[shake]"
    private static let moodPrefix = "[mood:"

    static func encode(_ text: String, shake: Bool, mood: ReminderMood? = nil) -> String {
        var markers: [String] = []
        if shake {
            markers.append(shakeMarker)
        }
        if let mood {
            markers.append("[mood:\(mood.rawValue)]")
        }
        guard !markers.isEmpty else { return text }
        return "\(markers.joined(separator: " ")) \(text)"
    }

    static func content(from rawText: String) -> ReminderContent {
        var remainder = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        var shouldShake = false
        var explicitMood: ReminderMood?

        var didConsumeMarker = true
        while didConsumeMarker {
            didConsumeMarker = false

            if remainder.hasPrefix(shakeMarker) {
                shouldShake = true
                remainder = String(remainder.dropFirst(shakeMarker.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                didConsumeMarker = true
            }

            if remainder.hasPrefix(moodPrefix),
               let closeIndex = remainder.firstIndex(of: "]") {
                let moodStart = remainder.index(remainder.startIndex, offsetBy: moodPrefix.count)
                let moodValue = String(remainder[moodStart..<closeIndex])
                explicitMood = ReminderMood(rawValue: moodValue)
                remainder = String(remainder[remainder.index(after: closeIndex)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                didConsumeMarker = true
            }
        }

        let displayText = remainder.isEmpty ? rawText : remainder
        return ReminderContent(
            displayText: displayText,
            shouldShake: shouldShake,
            mood: explicitMood ?? ReminderMood.infer(from: displayText, shouldShake: shouldShake)
        )
    }

    static func plainDisplayText(from rawText: String) -> String {
        ReminderMarkdown.plainText(from: content(from: rawText).displayText)
    }
}
