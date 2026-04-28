import SwiftUI

struct AssistantRootView: View {
    @ObservedObject var viewModel: AssistantViewModel
    let textWidth: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            AvatarView(mood: viewModel.mood)
                .offset(x: viewModel.isPresented ? 0 : -28, y: viewModel.isFloating ? -4 : 4)
                .opacity(viewModel.isPresented ? 1 : 0)

            ReminderBubble(text: viewModel.reminderText, textWidth: textWidth)
                .offset(x: viewModel.isPresented ? 0 : -20, y: viewModel.isFloating ? -6 : 2)
                .opacity(viewModel.isPresented ? 1 : 0)

            Spacer(minLength: 0)
        }
        .padding(.leading, 10)
        .padding(.trailing, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .background(Color.clear)
        .modifier(ShakeEffect(phase: viewModel.shakePhase))
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.dismiss()
        }
        .allowsHitTesting(viewModel.isPresented)
    }
}

private struct AvatarView: View {
    let mood: ReminderMood

    var body: some View {
        OriginalNanoPortraitView(mood: mood)
            .frame(width: 52, height: 52)
            .scaleEffect(1.1)
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color.black, lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.22), radius: 10, y: 6)
    }
}

private struct ReminderBubble: View {
    let text: String
    let textWidth: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            BubbleTail()
                .fill(Color.black.opacity(0.94))
                .frame(width: 10, height: 18)
                .offset(x: 2, y: 18)

            highlightedText
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: textWidth, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.94))
                )
        }
        .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
    }

    private var highlightedText: Text {
        var result = Text("")
        var remainder = text[...]
        var highlightIndex = 0

        while let start = remainder.range(of: "**") {
            result = result + plainText(String(remainder[..<start.lowerBound]))
            let afterStart = remainder[start.upperBound...]
            guard let end = afterStart.range(of: "**") else {
                result = result + plainText(String(remainder[start.lowerBound...]))
                return result
            }

            let emphasized = String(afterStart[..<end.lowerBound])
            if emphasized.isEmpty {
                result = result + plainText("****")
            } else {
                result = result + Text(emphasized).foregroundColor(highlightColor(at: highlightIndex))
                highlightIndex += 1
            }
            remainder = afterStart[end.upperBound...]
        }

        return result + plainText(String(remainder))
    }

    private func plainText(_ value: String) -> Text {
        Text(value).foregroundColor(.white)
    }

    private func highlightColor(at index: Int) -> Color {
        let colors = [
            Color(red: 1.0, green: 0.43, blue: 0.62),
            Color(red: 0.38, green: 0.78, blue: 1.0),
            Color(red: 0.74, green: 1.0, blue: 0.42),
            Color(red: 1.0, green: 0.78, blue: 0.28),
        ]
        return colors[index % colors.count]
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.midY)
        )
        path.addLine(to: CGPoint(x: rect.minX + 3, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct ShakeEffect: GeometryEffect {
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(phase * .pi * 8) * 7
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}
