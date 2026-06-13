import SwiftUI

struct CollaboratorsView: View {
    let project: Project
    @EnvironmentObject private var appState: AppState
    @State private var collaborators: [UserProfile] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var errorMessage: String?

    private var isOwner: Bool {
        project.ownerID == appState.currentUser?.id
    }

    @State private var ownerName: String = "..."

    var body: some View {
        List {
            Section("Owner") {
                if let user = appState.currentUser, project.ownerID == user.id {
                    CollaboratorRowView(profile: user, badge: "You")
                } else {
                    Text(ownerName)
                        .font(.subheadline)
                }
            }

            if !collaborators.isEmpty || isOwner {
                Section("Collaborators") {
                    ForEach(collaborators) { profile in
                        CollaboratorRowView(profile: profile, badge: nil)
                            .swipeActions(edge: .trailing) {
                                if isOwner {
                                    Button(role: .destructive) {
                                        Task { await remove(profile) }
                                    } label: {
                                        Label("Remove", systemImage: "person.badge.minus")
                                    }
                                }
                            }
                    }

                    if isOwner {
                        Button {
                            showAddSheet = true
                        } label: {
                            Label("Add Collaborator", systemImage: "person.badge.plus")
                        }
                    }
                }
            }
        }
        .navigationTitle("Collaborators")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await load() }
        .task {
            ownerName = await ProfileCache.shared.displayName(for: project.ownerID)
        }
        .sheet(isPresented: $showAddSheet) {
            AddCollaboratorView(projectID: project.id) { newProfile in
                collaborators.append(newProfile)
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        collaborators = (try? await CollaboratorService.shared.fetchCollaborators(projectID: project.id)) ?? []
    }

    private func remove(_ profile: UserProfile) async {
        do {
            try await CollaboratorService.shared.removeCollaborator(
                projectID: project.id,
                userID: profile.id
            )
            collaborators.removeAll { $0.id == profile.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct CollaboratorRowView: View {
    let profile: UserProfile
    let badge: String?

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.secondary.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(profile.displayName.prefix(1)).uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            Text(profile.displayName)
                .font(.subheadline)
            Spacer()
            if let badge {
                Text(badge)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }
}

struct AddCollaboratorView: View {
    @Environment(\.dismiss) private var dismiss
    let projectID: String
    var onAdded: ((UserProfile) -> Void)?

    @State private var query = ""
    @State private var results: [UserProfile] = []
    @State private var isSearching = false
    @State private var isAdding: String? = nil
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if results.isEmpty && !query.isEmpty && !isSearching {
                    ContentUnavailableView(
                        "No users found",
                        systemImage: "person.slash",
                        description: Text("Try a different name.")
                    )
                } else {
                    ForEach(results) { profile in
                        HStack {
                            CollaboratorRowView(profile: profile, badge: nil)
                            Spacer()
                            Button {
                                Task { await add(profile) }
                            } label: {
                                if isAdding == profile.id {
                                    ProgressView()
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.purple)
                                        .font(.title3)
                                }
                            }
                            .disabled(isAdding != nil)
                        }
                    }
                }
            }
            .navigationTitle("Add Collaborator")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .searchable(text: $query, prompt: "Search by name")
            .onChange(of: query) { _, new in
                Task { await search(new) }
            }
        }
    }

    private func search(_ q: String) async {
        guard q.count >= 2 else { results = []; return }
        isSearching = true
        defer { isSearching = false }
        results = (try? await CollaboratorService.shared.searchUsers(query: q)) ?? []
    }

    private func add(_ profile: UserProfile) async {
        isAdding = profile.id
        defer { isAdding = nil }
        do {
            try await CollaboratorService.shared.addCollaborator(
                projectID: projectID,
                userID: profile.id
            )
            onAdded?(profile)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
