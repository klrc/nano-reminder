import AppKit

struct ReminderWindowMetrics {
    let windowSize: NSSize
    let textWidth: CGFloat
    let textHeight: CGFloat
}

@MainActor
enum ReminderLayout {
    static let avatarSize: CGFloat = 52
    static let avatarScale: CGFloat = 1.1
    static let avatarLayoutSize = avatarSize
    static let avatarVisualSize = avatarSize * avatarScale
    static let avatarBubbleSpacing: CGFloat = 12
    static let leadingPadding: CGFloat = 10
    static let trailingPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 14
    static let bubbleTailWidth: CGFloat = 10
    static let bubbleHorizontalPadding: CGFloat = 16
    static let minTextWidth: CGFloat = 190
    static let maxTextWidth: CGFloat = 760
    static let minWindowWidth: CGFloat = 320
    static let maxWindowWidth: CGFloat = 920
    static let minWindowHeight: CGFloat = 128

    static func metrics(for text: String, choices: [String] = [], visibleFrame: NSRect) -> ReminderWindowMetrics {
        let availableWindowWidth = max(minWindowWidth, min(maxWindowWidth, visibleFrame.width - 36))
        let availableTextWidth = max(
            minTextWidth,
            availableWindowWidth - horizontalChromeWidth
        )
        let textWidth = min(
            max(minTextWidth, ceil(singleLineTextWidth(for: displayText(from: text)))),
            min(maxTextWidth, availableTextWidth)
        )

        let textBounds = ReminderMarkdown.measuredSize(for: displayText(from: text), width: textWidth)
        let bubbleVerticalPadding: CGFloat = 24
        let choiceHeight: CGFloat = choices.isEmpty ? 0 : 42
        let chromeHeight = verticalPadding * 2 + bubbleVerticalPadding + 20 + choiceHeight
        let maxHeight = max(minWindowHeight, visibleFrame.height - 48)
        let width = min(maxWindowWidth, max(minWindowWidth, ceil(textWidth + horizontalChromeWidth)))
        let height = min(max(minWindowHeight, ceil(textBounds.height) + chromeHeight), maxHeight)

        return ReminderWindowMetrics(
            windowSize: NSSize(width: width, height: height),
            textWidth: textWidth,
            textHeight: textBounds.height
        )
    }

    private static var horizontalChromeWidth: CGFloat {
        leadingPadding
            + avatarLayoutSize
            + avatarBubbleSpacing
            + bubbleTailWidth
            + bubbleHorizontalPadding * 2
            + trailingPadding
    }

    private static func singleLineTextWidth(for text: String) -> CGFloat {
        ReminderMarkdown.nsAttributedString(from: text).boundingRect(
            with: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).width
    }

    private static func displayText(from text: String) -> String {
        ReminderText.content(from: text).displayText
    }
}
