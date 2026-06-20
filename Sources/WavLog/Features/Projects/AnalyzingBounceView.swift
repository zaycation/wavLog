import SwiftUI

struct AnalyzingBounceView: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()

            VStack(spacing: 24) {
                vinyl
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }

                VStack(spacing: 6) {
                    Text("Analyzing your bounce...")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Detecting BPM, key, and structure")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    private var vinyl: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.08))
                .frame(width: 140, height: 140)
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 112, height: 112)
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 84, height: 84)
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 56, height: 56)
            Circle()
                .fill(Color.purple)
                .frame(width: 32, height: 32)
            Image(systemName: "music.note.list")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    AnalyzingBounceView()
}
