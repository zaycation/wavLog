import SwiftUI

struct AnimatedWaveformView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            WaveformCanvas(date: timeline.date)
        }
    }
}

private struct WaveformCanvas: View {
    let date: Date

    private let barCount = 44
    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            let t = date.timeIntervalSinceReferenceDate
            let totalWidth = CGFloat(barCount) * (barWidth + barSpacing) - barSpacing
            let startX = (size.width - totalWidth) / 2
            let centerY = size.height / 2
            let maxHalfHeight = size.height * 0.42

            for i in 0..<barCount {
                let x = startX + CGFloat(i) * (barWidth + barSpacing)
                let fi = Double(i)
                let n = Double(barCount)

                // Combine three sine waves at different frequencies for organic motion
                let p1 = t * 1.6 + fi * 0.28
                let p2 = t * 2.7 + fi * 0.17
                let p3 = t * 0.85 + fi * 0.44
                let raw = sin(p1) * 0.5 + sin(p2) * 0.3 + sin(p3) * 0.2
                let normalized = raw * 0.5 + 0.5  // 0…1

                // Bell-curve envelope so edges stay shorter than center
                let centerRatio = (fi - n / 2) / (n / 2)
                let envelope = 1.0 - centerRatio * centerRatio * 0.55
                let halfHeight = CGFloat(normalized * envelope) * maxHalfHeight + 6

                // Color: violet → blue → cyan along bar index
                let hue = 0.76 - (fi / n) * 0.22
                let color = Color(hue: hue, saturation: 0.78, brightness: 0.97)

                // Glow layer (wider, blurred-look via opacity)
                let glowRect = CGRect(
                    x: x - 3,
                    y: centerY - halfHeight - 6,
                    width: barWidth + 6,
                    height: halfHeight * 2 + 12
                )
                var glowCtx = context
                glowCtx.opacity = 0.18
                glowCtx.fill(
                    Path(roundedRect: glowRect, cornerRadius: (barWidth + 6) / 2),
                    with: .color(color)
                )

                // Main bar — symmetric top + bottom from center
                let barRect = CGRect(
                    x: x,
                    y: centerY - halfHeight,
                    width: barWidth,
                    height: halfHeight * 2
                )
                context.fill(
                    Path(roundedRect: barRect, cornerRadius: barWidth / 2),
                    with: .color(color.opacity(0.9))
                )
            }
        }
    }
}

#Preview {
    AnimatedWaveformView()
        .frame(height: 160)
        .background(.black)
}
