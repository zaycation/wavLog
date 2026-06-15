import SwiftUI

struct ProjectDetailView: View {
    @State var project: Project
    @State private var selectedTab: DetailTab

    init(project: Project, initialTab: DetailTab = .bounces) {
        _project = State(initialValue: project)
        _selectedTab = State(initialValue: initialTab)
    }

    @EnvironmentObject private var appState: AppState
    @State private var showCollaborators = false
    @State private var showArchiveConfirm = false
    @State private var showDeleteConfirm = false
    @State private var isArchiving = false

    enum DetailTab: String, CaseIterable {
        case bounces = "Bounces"
        case comments = "Feedback"
        case notes = "Notes"
    }

    private var isOwner: Bool {
        project.ownerID == appState.currentUser?.id
    }

    var body: some View {
        VStack(spacing: 0) {
            ProjectHeaderView(project: $project)
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
                    BounceHistoryView(project: $project)
                case .comments:
                    CommentThreadView(projectID: project.id)
                case .notes:
                    NotesView(project: $project)
                }
            }
        }
        .navigationTitle(project.title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showCollaborators = true
                        } label: {
                            Label("Collaborators", systemImage: "person.2")
                        }

                        if isOwner && !project.isArchived {
                            Button(role: .destructive) {
                                showArchiveConfirm = true
                            } label: {
                                Label("Archive Audio", systemImage: "archivebox")
                            }
                        }

                        if isOwner {
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete Project", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .navigationDestination(isPresented: $showCollaborators) {
                CollaboratorsView(project: project)
            }
            .confirmationDialog(
                "Archive Audio Files?",
                isPresented: $showArchiveConfirm,
                titleVisibility: .visible
            ) {
                Button("Archive", role: .destructive) {
                    Task { await archive() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all audio from storage. Metadata, comments, and bounce notes are kept permanently.")
            }
            .confirmationDialog(
                "Delete Project?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await delete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes the project and all its data.")
            }
    }

    private func archive() async {
        isArchiving = true
        defer { isArchiving = false }
        try? await ProjectService.shared.archiveProject(project)
        project.isArchived = true
    }

    private func delete() async {
        try? await ProjectService.shared.deleteProject(project)
    }
}

struct ProjectHeaderView: View {
    @Binding var project: Project
    @State private var isUpdatingStatus = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Menu {
                    ForEach(Project.Status.allCases, id: \.self) { status in
                        Button {
                            Task { await updateStatus(status) }
                        } label: {
                            Label(status.displayName, systemImage: statusIcon(status))
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        ProjectStatusBadge(status: project.status)
                        if isUpdatingStatus {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(isUpdatingStatus)

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

    private func updateStatus(_ status: Project.Status) async {
        isUpdatingStatus = true
        defer { isUpdatingStatus = false }
        guard let updated = try? await ProjectService.shared.updateStatus(project, status: status) else { return }
        project = updated
    }

    private func statusIcon(_ status: Project.Status) -> String {
        switch status {
        case .wip: "pencil.circle"
        case .shared: "person.2.circle"
        case .complete: "checkmark.circle"
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

struct NotesView: View {
    @Binding var project: Project
    @State private var editedNotes = ""
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var lastUpdated: Date? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lyrics & Notes")
                        .font(.headline)
                    if let date = lastUpdated {
                        Text("Updated \(date.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                Spacer()
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        Task { await saveNotes() }
                    } else {
                        editedNotes = project.lyricsNotes ?? ""
                        isEditing = true
                    }
                }
                .padding()
                .disabled(isSaving)
            }
            Divider()

            if isEditing {
                TextEditor(text: $editedNotes)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(
                        project.lyricsNotes?.isEmpty == false
                            ? project.lyricsNotes!
                            : "No notes yet. Tap Edit to add lyrics, structure, or ideas."
                    )
                    .foregroundStyle(project.lyricsNotes?.isEmpty == false ? .primary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding()
                }
            }
        }
        .onAppear {
            lastUpdated = project.updatedAt
        }
    }

    private func saveNotes() async {
        isSaving = true
        defer { isSaving = false }
        try? await ProjectService.shared.updateNotes(project, notes: editedNotes)
        project.lyricsNotes = editedNotes
        lastUpdated = .now
        isEditing = false
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: .preview)
            .environmentObject(AppState())
    }
}
