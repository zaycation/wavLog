import SwiftUI

struct ProjectCardStackView: View {
    let projects: [Project]
    let onSelect: (Project, ProjectDetailView.DetailTab) -> Void

    @State private var selectedID: Int?

    private let cardWidth: CGFloat = 260
    private let cardHeight: CGFloat = 440

    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geo in
                let hPad = max(0, (geo.size.width - cardWidth) / 2)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(
                            Array(projects.enumerated()),
                            id: \.offset
                        ) { index, project in
                            ProjectCard(
                                project: project,
                                onTap: { tab in onSelect(project, tab) }
                            )
                            .frame(width: cardWidth, height: cardHeight)
                            .id(index)
                            .scrollTransition(.animated) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.82)
                                    .opacity(phase.isIdentity ? 1.0 : 0.5)
                            }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, hPad)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $selectedID)
            }
            .frame(height: cardHeight + 20)

            if projects.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0 ..< projects.count, id: \.self) { i in
                        let isActive = i == (selectedID ?? 0)
                        Circle()
                            .fill(.white.opacity(isActive ? 1.0 : 0.3))
                            .frame(
                                width: isActive ? 8 : 5,
                                height: isActive ? 8 : 5
                            )
                            .animation(
                                .easeInOut(duration: 0.2),
                                value: isActive
                            )
                    }
                }
            }
        }
        .padding(.top, 32)
    }
}

// MARK: - ProjectCard

private struct ProjectCard: View {
    let project: Project
    let onTap: (ProjectDetailView.DetailTab) -> Void

    private static let waveformHeights: [CGFloat] = [
        20, 35, 55, 40, 65, 50, 30, 70, 45, 25,
        60, 38, 52, 44, 28, 66, 42, 58, 33, 48,
    ]

    var body: some View {
        Button(action: { onTap(.bounces) }) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 26.0 / 255, green: 26.0 / 255, blue: 36.0 / 255))

                VStack(alignment: .leading, spacing: 0) {
                    cardHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    Text(project.title)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    Text(metaLine)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    waveformArea
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    feedbackPreview
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    Spacer(minLength: 8)

                    metaRow
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(.white.opacity(0.1))
                                .frame(height: 1)
                        }

                    actionRow
                        .padding(.horizontal, 8)
                        .padding(.bottom, 16)
                }
            }
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private var cardHeader: some View {
        HStack {
            HStack(spacing: 4) {
                Text(project.status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(project.status.color.opacity(0.2))
            .foregroundStyle(project.status.color)
            .clipShape(Capsule())

            Spacer()

            HStack(spacing: -8) {
                ForEach(0 ..< 2, id: \.self) { _ in
                    Circle()
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 28, height: 28)
                        .overlay { Circle().stroke(.black, lineWidth: 2) }
                }
            }
        }
    }

    private var metaLine: String {
        let diff = Date.now.timeIntervalSince(project.updatedAt)
        let hours = max(1, Int(diff / 3600))
        if hours < 24 {
            return "\(hours)h ago · 3 versions · 2 comments"
        }
        let days = hours / 24
        return "\(days)d ago · 3 versions · 2 comments"
    }

    private var waveformArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.12))

            HStack(alignment: .center, spacing: 3) {
                ForEach(
                    Array(Self.waveformHeights.enumerated()),
                    id: \.offset
                ) { _, height in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.purple.opacity(0.55))
                        .frame(width: 4, height: height)
                }
            }

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.9))
                        .offset(x: 2)
                }
        }
        .frame(height: 100)
    }

    private var feedbackPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LATEST FEEDBACK")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            Text("No feedback yet")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
                .italic()
        }
    }

    private var metaRow: some View {
        HStack {
            Spacer()
            if let bpm = project.bpm {
                metaItem(value: "\(bpm)", label: "BPM")
                Spacer()
            }
            if let key = project.key {
                metaItem(value: key, label: "KEY")
                Spacer()
            }
            if let genre = project.genre {
                metaItem(value: genre, label: "GENRE")
                Spacer()
            }
        }
    }

    private var actionRow: some View {
        HStack {
            Spacer()
            actionButton(icon: "bubble.left", label: "FEEDBACK") {
                onTap(.comments)
            }
            Spacer()
            actionButton(icon: "text.alignleft", label: "LYRICS") {
                onTap(.notes)
            }
            Spacer()
            actionButton(icon: "square.and.arrow.up", label: "SHARE") {
                // TODO: share flow
            }
            Spacer()
        }
    }

    private func metaItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 19))
                    .foregroundStyle(.white.opacity(0.7))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ProjectCardStackView(
            projects: [.preview, .preview, .preview],
            onSelect: { _, _ in }
        )
    }
}
