import SwiftUI

struct AudioPlayerView: View {
    @ObservedObject private var player = AudioPlayer.shared
    let url: URL
    var label: String?
    var waveform: [Double]?

    private var progress: Double {
        guard player.duration > 0 else { return 0 }
        return player.currentTime / player.duration
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    player.togglePlayback()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.primary)
                }
                .disabled(player.isLoading || player.error != nil)

                VStack(alignment: .leading, spacing: 4) {
                    if let waveform, !waveform.isEmpty {
                        WaveformScrubberView(samples: waveform, progress: progress) { fraction in
                            player.seek(to: fraction * player.duration)
                        }
                        .frame(height: 36)
                        .disabled(player.duration == 0)
                    } else {
                        Slider(
                            value: Binding(
                                get: { player.currentTime },
                                set: { player.seek(to: $0) }
                            ),
                            in: 0 ... max(player.duration, 1)
                        )
                        .disabled(player.duration == 0)
                    }

                    HStack {
                        Text(formatTime(player.currentTime))
                        Spacer()
                        Text(formatTime(player.duration))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                }
            }

            if player.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if let error = player.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { player.load(url: url) }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
