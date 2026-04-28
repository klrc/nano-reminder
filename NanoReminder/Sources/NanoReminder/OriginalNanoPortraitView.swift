import AppKit
import SwiftUI

struct OriginalNanoPortraitView: View {
    let mood: ReminderMood

    init(mood: ReminderMood = .defaultMood) {
        self.mood = mood
    }

    var body: some View {
        if let url = Bundle.module.url(forResource: mood.assetName, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.98, green: 0.8, blue: 0.82), Color(red: 0.98, green: 0.9, blue: 0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text("Nano")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}
