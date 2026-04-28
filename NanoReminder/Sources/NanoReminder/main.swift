import AppKit
import SwiftUI

struct LaunchConfig {
    let isResident: Bool
    let initialMessage: String?
    let quitsAfterInitialMessage: Bool
}

func argumentValue(named name: String) -> String? {
    let args = Array(CommandLine.arguments.dropFirst())
    guard let index = args.firstIndex(of: name), args.indices.contains(index + 1) else {
        return nil
    }
    return args[index + 1]
}

func positionalMessage(from args: [String], droppingFirst: Bool = false) -> String? {
    let values = droppingFirst ? Array(args.dropFirst()) : args
    var messageParts: [String] = []
    var i = 0

    while i < values.count {
        switch values[i] {
        case "--text", "--message", "--mood":
            i += 2
        case "--shake", "--resident":
            i += 1
        default:
            if !values[i].hasPrefix("--") {
                messageParts.append(values[i])
            }
            i += 1
        }
    }

    return messageParts.joined(separator: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .nilIfEmpty
}

let app = NSApplication.shared
let args = Array(CommandLine.arguments.dropFirst())
let shouldShakeInitialMessage = args.contains("--shake")

// Run migration first
DataMigrator.migrateIfNeeded()

// Check for CLI mode
if args.contains("--help") || args.contains("-h") {
    CLIOutput.printUsage()
    exit(0)
}

if let first = args.first, ["add", "list", "delete", "clean"].contains(first) {
    do {
        let command = try CLICommand.parse(arguments: args)
        let output = try command.execute()
        print(output)
    } catch {
        CLIOutput.printError(error.localizedDescription)
        exit(1)
    }
    exit(0)
}

let showText: String?
if args.first == "show" {
    showText = argumentValue(named: "--text")
        ?? positionalMessage(from: args, droppingFirst: true)
    if showText == nil {
        CLIOutput.printError("用法: nano-reminder show --text <内容>")
        exit(1)
    }
} else {
    showText = nil
}

let initialMessage = showText
    ?? argumentValue(named: "--message")
    ?? positionalMessage(from: args)

let explicitMood: ReminderMood?
if let moodValue = argumentValue(named: "--mood") {
    guard let parsedMood = ReminderMood(rawValue: moodValue) else {
        CLIOutput.printError("--mood 必须是: \(ReminderMood.usageList)")
        exit(1)
    }
    explicitMood = parsedMood
} else {
    explicitMood = nil
}

// --resident or no args -> resident mode (default when launched as .app)
let launchConfig = LaunchConfig(
    isResident: args.contains("--resident") || args.isEmpty,
    initialMessage: initialMessage.map { ReminderText.encode($0, shake: shouldShakeInitialMessage, mood: explicitMood) },
    quitsAfterInitialMessage: showText != nil
)

let delegate = AppDelegate(launchConfig: launchConfig)
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
