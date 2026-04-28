import SwiftUI

struct AssistantRootView: View {
    @ObservedObject var viewModel: AssistantViewModel

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            AvatarView()
                .offset(x: viewModel.isPresented ? 0 : -28, y: viewModel.isFloating ? -4 : 4)
                .opacity(viewModel.isPresented ? 1 : 0)

            ReminderBubble(text: viewModel.reminderText)
                .offset(x: viewModel.isPresented ? 0 : -20, y: viewModel.isFloating ? -6 : 2)
                .opacity(viewModel.isPresented ? 1 : 0)

            Spacer(minLength: 0)
        }
        .padding(.leading, 10)
        .padding(.trailing, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.dismiss()
        }
        .allowsHitTesting(viewModel.isPresented)
    }
}

private struct AvatarView: View {
    var body: some View {
        OriginalNanoPortraitView()
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
    
    var body: some View {
        HStack(spacing: 0) {
            BubbleTail()
                .fill(Color.black.opacity(0.94))
                .frame(width: 10, height: 18)
                .offset(x: 2, y: 18)

            Text(text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 510, alignment: .leading)
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
