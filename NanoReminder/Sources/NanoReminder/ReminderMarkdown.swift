import AppKit
import SwiftUI

enum ReminderMarkdown {
    static let fontSize: CGFloat = 15
    static let lineSpacing: CGFloat = 4

    private static let textColor = NSColor.white
    private static let mutedColor = NSColor.white.withAlphaComponent(0.72)
    private static let strongColor = NSColor(calibratedRed: 0.45, green: 0.88, blue: 1.0, alpha: 1)
    private static let emphasisColor = NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.28, alpha: 1)
    private static let codeColor = NSColor(calibratedRed: 0.74, green: 1.0, blue: 0.42, alpha: 1)

    static func nsAttributedString(from markdown: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)

        var inCodeBlock = false

        for rawLine in lines {
            var line = String(rawLine)
            var style = LineStyle.body

            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                inCodeBlock.toggle()
                continue
            }

            if inCodeBlock {
                style = .codeBlock
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                appendNewlineIfNeeded(to: result)
                continue
            } else if line.range(of: #"^\s*#{1,6}\s+"#, options: .regularExpression) != nil {
                let level = line.prefix { $0 == "#" }.count
                line = line.replacingOccurrences(of: #"^\s*#{1,6}\s+"#, with: "", options: .regularExpression)
                style = .heading(level: level)
            } else if line.range(of: #"^\s*([-*_])\s*\1\s*\1\s*$"#, options: .regularExpression) != nil {
                line = "────────────"
                style = .rule
            } else if line.range(of: #"^\s*>\s?"#, options: .regularExpression) != nil {
                line = "▏ " + line.replacingOccurrences(of: #"^\s*>\s?"#, with: "", options: .regularExpression)
                style = .quote
            } else if line.range(of: #"^\s*[-*+]\s+"#, options: .regularExpression) != nil {
                line = "• " + line.replacingOccurrences(of: #"^\s*[-*+]\s+"#, with: "", options: .regularExpression)
                style = .list
            } else if line.range(of: #"^\s*\d+[.)]\s+"#, options: .regularExpression) != nil {
                line = line.replacingOccurrences(of: #"^\s*"#, with: "", options: .regularExpression)
                style = .list
            }

            appendNewlineIfNeeded(to: result)
            let lineRange = NSRange(location: result.length, length: line.utf16.count)
            result.append(NSAttributedString(string: line, attributes: style.attributes))

            if style.allowsInlineMarkdown {
                applyInlineMarkdown(to: result, in: lineRange)
            }
        }

        return result
    }

    static func plainText(from markdown: String) -> String {
        nsAttributedString(from: markdown).string
    }

    static func measuredSize(for markdown: String, width: CGFloat) -> NSSize {
        let attributed = nsAttributedString(from: markdown)
        let storage = NSTextStorage(attributedString: attributed)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: NSSize(width: width, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        textContainer.widthTracksTextView = false
        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        layoutManager.ensureLayout(for: textContainer)
        let rect = layoutManager.usedRect(for: textContainer)
        return NSSize(width: ceil(rect.width), height: ceil(rect.height))
    }

    private static func appendNewlineIfNeeded(to result: NSMutableAttributedString) {
        if result.length > 0 {
            result.append(NSAttributedString(string: "\n"))
        }
    }

    private static func applyInlineMarkdown(to string: NSMutableAttributedString, in range: NSRange) {
        apply(pattern: #"`([^`]+)`"#, to: string, in: range) { matchRange in
            string.addAttributes([
                .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: codeColor,
            ], range: matchRange)
        }
        apply(pattern: #"\*\*([^*]+)\*\*"#, to: string, in: range) { matchRange in
            string.addAttributes([
                .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: strongColor,
            ], range: matchRange)
        }
        apply(pattern: #"(?<!\*)\*([^*]+)\*(?!\*)"#, to: string, in: range) { matchRange in
            string.addAttributes([
                .font: NSFontManager.shared.convert(NSFont.systemFont(ofSize: fontSize, weight: .semibold), toHaveTrait: .italicFontMask),
                .foregroundColor: emphasisColor,
            ], range: matchRange)
        }
        for marker in ["`", "**", "*"] {
            string.mutableString.replaceOccurrences(
                of: marker,
                with: "",
                options: [],
                range: NSRange(location: range.location, length: max(0, min(range.length, string.length - range.location)))
            )
        }
    }

    private static func apply(pattern: String, to string: NSMutableAttributedString, in range: NSRange, body: (NSRange) -> Void) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let matches = regex.matches(in: string.string, range: range)
        for match in matches.reversed() where match.numberOfRanges > 1 {
            body(match.range(at: 1))
        }
    }

    private enum LineStyle {
        case body
        case heading(level: Int)
        case list
        case quote
        case rule
        case codeBlock

        var allowsInlineMarkdown: Bool {
            switch self {
            case .codeBlock, .rule:
                false
            default:
                true
            }
        }

        var attributes: [NSAttributedString.Key: Any] {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = lineSpacing
            paragraph.lineBreakMode = .byWordWrapping

            switch self {
            case .body:
                return [.font: NSFont.systemFont(ofSize: fontSize, weight: .semibold), .foregroundColor: textColor, .paragraphStyle: paragraph]
            case .heading(let level):
                let size = max(fontSize + 1, fontSize + CGFloat(5 - min(level, 5)))
                paragraph.paragraphSpacingBefore = 4
                paragraph.paragraphSpacing = 3
                return [.font: NSFont.systemFont(ofSize: size, weight: .bold), .foregroundColor: textColor, .paragraphStyle: paragraph]
            case .list:
                paragraph.firstLineHeadIndent = 0
                paragraph.headIndent = 18
                return [.font: NSFont.systemFont(ofSize: fontSize, weight: .semibold), .foregroundColor: textColor, .paragraphStyle: paragraph]
            case .quote:
                return [.font: NSFont.systemFont(ofSize: fontSize, weight: .semibold), .foregroundColor: mutedColor, .paragraphStyle: paragraph]
            case .rule:
                return [.font: NSFont.systemFont(ofSize: fontSize, weight: .semibold), .foregroundColor: mutedColor, .paragraphStyle: paragraph]
            case .codeBlock:
                return [.font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .semibold), .foregroundColor: codeColor, .paragraphStyle: paragraph]
            }
        }
    }
}

struct MarkdownTextView: NSViewRepresentable {
    let markdown: String
    let width: CGFloat

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        return textView
    }

    func updateNSView(_ textView: NSTextView, context: Context) {
        textView.textStorage?.setAttributedString(ReminderMarkdown.nsAttributedString(from: markdown))
        textView.frame.size.width = width
        textView.textContainer?.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)
    }
}
