import SwiftUI
import UniformTypeIdentifiers

struct ProjectListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var projects: [Project] = []
    @State private var showCreateProject = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var selectedProject: Project? = nil

    #if os(macOS)
    @State private var isDAWDropTargeted = false
    @State private var dawImportResult: DAWImportResult?
    @State private var showDAWReview = false
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if isLoading && projects.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if projects.isEmpty {
                        ContentUnavailableView(
                            "No Projects Yet",
                            systemImage: "music.note",
                            description: Text("Log your first beat or drop a DAW file to get started.")
                        )
                    } else {
                        List(projects) { project in
                            Button {
                                selectedProject = project
                            } label: {
                                ProjectRowView(project: project)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if project.ownerID == appState.currentUser?.id {
                                    Button(role: .destructive) {
                                        Task { await delete(project) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .navigationDestination(item: $selectedProject) { project in
                            ProjectDetailView(project: project)
                        }
                        #if os(iOS)
                        .listStyle(.insetGrouped)
                        #else
                        .listStyle(.inset)
                        #endif
                    }
                }

                #if os(macOS)
                if isDAWDropTargeted {
                    DAWDropOverlay(isTargeted: $isDAWDropTargeted)
                        .padding()
                        .allowsHitTesting(false)
                }
                #endif
            }
            .navigationTitle("Projects")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showCreateProject) {
                CreateProjectView { newProject in
                    projects.insert(newProject, at: 0)
                }
            }
            .task { await loadProjects() }
            .refreshable { await loadProjects() }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            #if os(macOS)
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first else { return false }
                let ext = url.pathExtension.lowercased()
                guard ["logicx", "als", "flp"].contains(ext) else { return false }
                let result = DAWImportParser.parse(url: url)
                dawImportResult = result
                showDAWReview = true
                return true
            } isTargeted: { targeted in
                isDAWDropTargeted = targeted
            }
            .sheet(isPresented: $showDAWReview) {
                if let result = dawImportResult {
                    DAWImportReviewView(result: result) { draft in
                        Task {
                            if let project = try? await ProjectService.shared.createProject(draft) {
                                projects.insert(project, at: 0)
                            }
                        }
                    }
                }
            }
            #endif
        }
    }

    private func loadProjects() async {
        isLoading = true
        defer { isLoading = false }
        do {
            projects = try await ProjectService.shared.fetchProjects()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ project: Project) async {
        do {
            try await ProjectService.shared.deleteProject(project)
            projects.removeAll { $0.id == project.id }
        } catch {
            errorMessage = error.localizedDescription
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
        .environmentObject(AppState())
}
