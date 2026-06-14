import SwiftUI

struct ProjectGridView: View {
    let projects: [Project]
    let onSelect: (Project) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(projects) { project in
                    Button { onSelect(project) } label: {
                        ProjectGridCard(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

private struct ProjectGridCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ProjectStatusBadge(status: project.status)
                Spacer()
            }

            Text(project.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundStyle(.primary)

            if let bpm = project.bpm {
                Text("\(bpm) BPM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ProjectGridView(
        projects: [.preview, .preview, .preview, .preview],
        onSelect: { _ in }
    )
}
