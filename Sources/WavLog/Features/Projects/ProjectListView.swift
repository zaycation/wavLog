import SwiftUI

struct ProjectListView: View {
    @State private var projects: [Project] = []
    @State private var showCreateProject = false

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "No Projects Yet",
                        systemImage: "music.note",
                        description: Text("Log your first beat to get started.")
                    )
                } else {
                    List(projects) { project in
                        NavigationLink(destination: ProjectDetailView(project: project)) {
                            ProjectRowView(project: project)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateProject) {
                CreateProjectView()
            }
        }
    }
}

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(project.title)
                    .font(.headline)
                Spacer()
                ProjectStatusBadge(status: project.status)
            }
            HStack(spacing: 12) {
                if let bpm = project.bpm {
                    Label("\(bpm) BPM", systemImage: "metronome")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let key = project.key {
                    Label(key, systemImage: "music.quarternote.3")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProjectStatusBadge: View {
    let status: Project.Status

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.color.opacity(0.15))
            .foregroundStyle(status.color)
            .clipShape(Capsule())
    }
}

#Preview {
    ProjectListView()
}
