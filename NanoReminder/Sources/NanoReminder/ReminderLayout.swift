import AppKit

struct ReminderWindowMetrics {
    let windowSize: NSSize
    let textWidth: CGFloat
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
    static let minTextWidth: CGFloat = 150
    static let maxTextWidth: CGFloat = 510
    static let minWindowWidth: CGFloat = 320
    static let maxWindowWidth: CGFloat = 660
    static let minWindowHeight: CGFloat = 128

    private static var textFont: NSFont {
        NSFont.systemFont(ofSize: 15, weight: .semibold)
    }

    static func metrics(for text: String, visibleFrame: NSRect) -> ReminderWindowMetrics {
        let availableWindowWidth = max(minWindowWidth, min(maxWindowWidth, visibleFrame.width - 36))
        let availableTextWidth = max(
            minTextWidth,
            availableWindowWidth - horizontalChromeWidth
        )
        let textWidth = min(
            max(minTextWidth, ceil(singleLineTextWidth(for: displayText(from: text)))),
            min(maxTextWidth, availableTextWidth)
        )

        let textBounds = (displayText(from: text) as NSString).boundingRect(
            with: NSSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: textFont]
        )
        let chromeHeight = verticalPadding * 2 + 64
        let maxHeight = max(minWindowHeight, visibleFrame.height - 80)
        let width = min(maxWindowWidth, max(minWindowWidth, ceil(textWidth + horizontalChromeWidth)))
        let height = min(max(minWindowHeight, ceil(textBounds.height) + chromeHeight), maxHeight)

        return ReminderWindowMetrics(
            windowSize: NSSize(width: width, height: height),
            textWidth: textWidth
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
        (text as NSString).boundingRect(
            with: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: textFont]
        ).width
    }

    private static func displayText(from text: String) -> String {
        ReminderText.plainDisplayText(from: text)
    }
}
