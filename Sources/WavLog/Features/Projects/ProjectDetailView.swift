import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @State private var selectedTab = DetailTab.bounces

    enum DetailTab: String, CaseIterable {
        case bounces = "Bounces"
        case comments = "Feedback"
        case notes = "Notes"
    }

    var body: some View {
        VStack(spacing: 0) {
            ProjectHeaderView(project: project)
                .padding()

            Picker("Tab", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            Group {
                switch selectedTab {
                case .bounces:
                    BounceHistoryView(projectID: project.id)
                case .comments:
                    CommentThreadView(projectID: project.id)
                case .notes:
                    NotesView(project: project)
                }
            }
        }
        .navigationTitle(project.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct ProjectHeaderView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ProjectStatusBadge(status: project.status)
                Spacer()
                if project.isArchived {
                    Label("Archived", systemImage: "archivebox")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 24) {
                if let bpm = project.bpm {
                    MetadataItem(label: "BPM", value: "\(bpm)")
                }
                if let key = project.key {
                    MetadataItem(label: "Key", value: key)
                }
                if let genre = project.genre {
                    MetadataItem(label: "Genre", value: genre)
                }
            }

            if let influences = project.influences, !influences.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("References")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(influences)
                        .font(.subheadline)
                }
            }
        }
    }
}

struct MetadataItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct BounceHistoryView: View {
    let projectID: String

    var body: some View {
        Text("Bounce history — coming soon")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NotesView: View {
    let project: Project

    var body: some View {
        Text(project.lyricsNotes ?? "No notes yet.")
            .foregroundStyle(project.lyricsNotes == nil ? .secondary : .primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: .preview)
    }
}
