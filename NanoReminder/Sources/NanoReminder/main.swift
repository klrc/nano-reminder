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

let app = NSApplication.shared
let args = Array(CommandLine.arguments.dropFirst())

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
        ?? Array(args.dropFirst()).filter { !$0.hasPrefix("--") }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    if showText == nil {
        CLIOutput.printError("用法: nano-reminder show --text <内容>")
        exit(1)
    }
} else {
    showText = nil
}

// --resident or no args -> resident mode (default when launched as .app)
let launchConfig = LaunchConfig(
    isResident: args.contains("--resident") || args.isEmpty,
    initialMessage: showText
        ?? argumentValue(named: "--message")
        ?? args.filter { !$0.hasPrefix("--") }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
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
