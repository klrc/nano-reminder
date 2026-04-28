import Foundation

enum ReminderMood: String, CaseIterable {
    case calm
    case happy
    case grateful
    case confused
    case ask
    case panic
    case shocked

    static let defaultMood: ReminderMood = .calm

    var assetName: String {
        switch self {
        case .calm:
            "nano-face-cute-real"
        case .happy:
            "nano-mood-happy"
        case .grateful:
            "nano-mood-grateful"
        case .confused:
            "nano-mood-confused"
        case .ask:
            "nano-mood-ask"
        case .panic:
            "nano-mood-panic"
        case .shocked:
            "nano-mood-shocked"
        }
    }

    static func infer(from text: String, shouldShake: Bool) -> ReminderMood {
        let lowercased = text.lowercased()

        if shouldShake || lowercased.containsAny(of: ["urgent", "panic", "紧急", "快", "马上", "立刻", "赶紧", "炸了"]) {
            return .panic
        }

        if lowercased.containsAny(of: ["error", "failed", "fail", "失败", "错误", "报错", "崩", "坏了"]) {
            return .shocked
        }

        if lowercased.containsAny(of: ["why", "?", "？", "不对", "奇怪", "疑问", "看看"]) {
            return .confused
        }

        if lowercased.containsAny(of: ["thanks", "thank", "感恩", "感谢", "谢谢", "辛苦"]) {
            return .grateful
        }

        if lowercased.containsAny(of: ["done", "success", "complete", "完成", "成功", "通过", "好了", "可以回来"]) {
            return .happy
        }

        return .defaultMood
    }

    static var usageList: String {
        allCases.map(\.rawValue).joined(separator: "|")
    }
}

private extension String {
    func containsAny(of needles: [String]) -> Bool {
        needles.contains { contains($0) }
    }
}
