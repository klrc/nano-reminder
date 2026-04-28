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
            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(choices, id: \.self) { choice in
                    Button {
                        onChoose(choice)
                    } label: {
                        Text(choice)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 14)
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

private struct FlowLayout: Layout {
    let spacing: CGFloat
    let rowSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        let rows = rows(for: subviews, maxWidth: maxWidth)
        return CGSize(
            width: rows.map(\.width).max() ?? 0,
            height: rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * rowSpacing
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY

        for row in rows(for: subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + rowSpacing
        }
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [FlowRow] {
        var rows: [FlowRow] = []
        var current = FlowRow()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let nextWidth = current.items.isEmpty ? size.width : current.width + spacing + size.width
            if !current.items.isEmpty, nextWidth > maxWidth {
                rows.append(current)
                current = FlowRow()
            }
            current.items.append(FlowItem(index: index, size: size))
            current.width = current.items.count == 1 ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
        }

        if !current.items.isEmpty {
            rows.append(current)
        }
        return rows
    }

    private struct FlowItem {
        let index: Int
        let size: CGSize
    }

    private struct FlowRow {
        var items: [FlowItem] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
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
