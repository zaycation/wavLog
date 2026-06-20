import SwiftUI

/// SoundCloud-style waveform scrubber: filled bars up to playback progress,
/// dimmed bars after. Dragging seeks.
struct WaveformScrubberView: View {
    let samples: [Double]
    let progress: Double
    var onSeek: (Double) -> Void

    private static let barCount = 50

    var body: some View {
        let bars = MusicUnderstandingService.resample(samples, targetCount: Self.barCount)
        let peak = max(bars.max() ?? 1, 0.0001)

        GeometryReader { geo in
            HStack(alignment: .center, spacing: 2) {
                ForEach(Array(bars.enumerated()), id: \.offset) { index, value in
                    let barProgress = Double(index) / Double(max(bars.count - 1, 1))
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(barProgress <= progress ? Color.purple : Color.secondary.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: max(3, CGFloat(value / peak) * geo.size.height))
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let clamped = min(max(value.location.x / geo.size.width, 0), 1)
                        onSeek(clamped)
                    }
            )
        }
    }
}
