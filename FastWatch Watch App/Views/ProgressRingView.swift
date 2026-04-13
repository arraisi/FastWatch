import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    init(progress: Double, color: Color, lineWidth: CGFloat = 12) {
        self.progress = progress
        self.color = color
        self.lineWidth = lineWidth
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var isOvertime: Bool {
        progress > 1.0
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Overtime pulse
            if isOvertime {
                Circle()
                    .stroke(color, lineWidth: lineWidth)
                    .rotationEffect(.degrees(-90))
                    .opacity(pulseOpacity)
            }
        }
        .padding(lineWidth / 2)
    }

    @State private var pulseOpacity: Double = 1.0

    private var pulsingBody: some View {
        body
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseOpacity = 0.5
                }
            }
    }
}

struct ProgressRingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProgressRingView(progress: 0.0, color: .green)
                .previewDisplayName("0%")
            ProgressRingView(progress: 0.25, color: .green)
                .previewDisplayName("25%")
            ProgressRingView(progress: 0.5, color: .teal)
                .previewDisplayName("50%")
            ProgressRingView(progress: 0.75, color: .blue)
                .previewDisplayName("75%")
            ProgressRingView(progress: 1.0, color: .yellow)
                .previewDisplayName("100%")
            ProgressRingView(progress: 1.2, color: .yellow)
                .previewDisplayName("120% Overtime")
        }
        .frame(width: 150, height: 150)
    }
}
