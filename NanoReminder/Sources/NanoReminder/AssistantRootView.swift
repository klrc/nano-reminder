import SwiftUI

struct AssistantRootView: View {
    @ObservedObject var viewModel: AssistantViewModel
    let textWidth: CGFloat
    let textHeight: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            AvatarView(mood: viewModel.mood)
                .offset(x: viewModel.isPresented ? 0 : -28, y: viewModel.isFloating ? -4 : 4)
                .opacity(viewModel.isPresented ? 1 : 0)

            ReminderBubble(
                text: viewModel.reminderText,
                choices: viewModel.choices,
                textWidth: textWidth,
                textHeight: textHeight,
                onChoose: viewModel.choose
            )
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
    let choices: [String]
    let textWidth: CGFloat
    let textHeight: CGFloat
    let onChoose: (String) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            BubbleTail()
                .fill(Color.black.opacity(0.94))
                .frame(width: 10, height: 18)
                .offset(x: 2, y: 18)

            VStack(alignment: .leading, spacing: 10) {
                MarkdownTextView(markdown: text, width: textWidth)
                    .frame(width: textWidth, height: textHeight, alignment: .leading)

                ChoiceButtons(choices: choices, onChoose: onChoose)
                    .frame(width: textWidth, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.94))
            )
        }
        .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
    }
}

private struct ChoiceButtons: View {
    let choices: [String]
    let onChoose: (String) -> Void

    var body: some View {
        if !choices.isEmpty {
            HStack(spacing: 8) {
                ForEach(choices, id: \.self) { choice in
                    Button {
                        onChoose(choice)
                    } label: {
                        Text(choice)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.92))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
