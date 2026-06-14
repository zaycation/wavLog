
import PhotosUI
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var activityDays: [ActivityDay] = []
    @State private var isLoadingActivity = false
    @State private var showEditName = false

    @AppStorage("wavlog_project_view") private var viewStyleRaw: String = ProjectViewStyle.cards.rawValue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ProfileHeaderView(
                        user: appState.currentUser,
                        onEditTapped: { showEditName = true }
                    )
                    ActivityChartView(days: activityDays, isLoading: isLoadingActivity)
                    ProjectViewPreference(selection: $viewStyleRaw)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        NavigationLink(destination: InviteManagerView()) {
                            Label("Invites", systemImage: "envelope.badge")
                        }
                        Divider()
                        Button(role: .destructive) {
                            Task { await appState.signOut() }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task { await loadActivity() }
            .sheet(isPresented: $showEditName) {
                EditDisplayNameView(
                    currentName: appState.currentUser?.displayName ?? ""
                ) { newName in
                    appState.currentUser?.displayName = newName
                }
            }
        }
    }

    private func loadActivity() async {
        guard let userID = appState.currentUser?.id else { return }
        isLoadingActivity = true
        defer { isLoadingActivity = false }
        activityDays = (try? await ProfileService.shared.fetchActivityCounts(userID: userID)) ?? []
    }
}

struct ProfileHeaderView: View {
    let user: UserProfile?
    var onEditTapped: (() -> Void)? = nil
    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var localAvatar: UIImage?

    var body: some View {
        HStack(spacing: 16) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack {
                    Circle()
                        .fill(.secondary.opacity(0.2))
                        .frame(width: 72, height: 72)
                        .overlay {
                            if let localAvatar {
                                Image(uiImage: localAvatar)
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                            } else if let avatarURL = user?.avatarURL, let url = URL(string: avatarURL) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .clipShape(Circle())
                            } else {
                                Text(user.map { String($0.displayName.prefix(1)).uppercased() } ?? "?")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                        }

                    if isUploading {
                        Circle()
                            .fill(.black.opacity(0.5))
                            .frame(width: 72, height: 72)
                            .overlay { ProgressView().tint(.white) }
                    }
                }
            }
            .buttonStyle(.plain)
            .onChange(of: selectedItem) { _, newVal in
                guard let newVal else { return }
                Task {
                    await handleImageSelection(newVal)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Button {
                    onEditTapped?()
                } label: {
                    HStack(spacing: 6) {
                        Text(user?.displayName ?? "Loading...")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        if onEditTapped != nil {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    private func handleImageSelection(_ item: PhotosPickerItem) async {
        isUploading = true
        defer { isUploading = false }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

        localAvatar = image

        do {
            let url = try await ProfileService.shared.uploadAvatar(imageData: data)
            // Update the user model so it persists
            if var user = user as? UserProfile {
                // URL is saved in DB, will load on next session
            }
        } catch {
            print("Avatar upload failed: \(error)")
        }
    }
}

struct EditDisplayNameView: View {
    @Environment(\.dismiss) private var dismiss
    var currentName: String = ""
    var onSaved: ((String) -> Void)?

    @State private var name: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    init(currentName: String = "", onSaved: ((String) -> Void)? = nil) {
        self.currentName = currentName
        self.onSaved = onSaved
        _name = State(initialValue: currentName)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display name", text: $name)
                        .focused($focused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                } footer: {
                    Text("This is how collaborators see you in the app.")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Name")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Button("Save") {
                                Task { await save() }
                            }
                            .disabled(!canSave)
                            .fontWeight(.semibold)
                        }
                    }
                }
                .onAppear { focused = true }
        }
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            try await ProfileService.shared.updateDisplayName(trimmed)
            onSaved?(trimmed)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ActivityChartView: View {
    let days: [ActivityDay]
    let isLoading: Bool

    private let columns = 52
    private let rows = 7
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)

            if isLoading {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.secondary.opacity(0.1))
                    .frame(maxWidth: .infinity)
                    .frame(height: CGFloat(rows) * (cellSize + cellSpacing))
                    .overlay { ProgressView() }
            } else {
                let grid = buildGrid()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: cellSpacing) {
                        ForEach(0 ..< columns, id: \.self) { col in
                            VStack(spacing: cellSpacing) {
                                ForEach(0 ..< rows, id: \.self) { row in
                                    let count = grid[col][row]
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(cellColor(count: count))
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 6) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach([0, 1, 3, 5, 8], id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(cellColor(count: level))
                            .frame(width: cellSize, height: cellSize)
                    }
                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func cellColor(count: Int) -> Color {
        switch count {
        case 0: return .secondary.opacity(0.15)
        case 1 ... 2: return .green.opacity(0.35)
        case 3 ... 4: return .green.opacity(0.55)
        case 5 ... 7: return .green.opacity(0.75)
        default: return .green
        }
    }

    private func buildGrid() -> [[Int]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var countMap: [String: Int] = [:]
        for day in days {
            countMap[day.dateString] = day.count
        }

        let today = Date.now
        let calendar = Calendar.current
        var grid = Array(repeating: Array(repeating: 0, count: rows), count: columns)

        for col in 0 ..< columns {
            for row in 0 ..< rows {
                let daysBack = (columns - 1 - col) * 7 + (rows - 1 - row)
                guard let date = calendar.date(byAdding: .day, value: -daysBack, to: today) else { continue }
                let key = formatter.string(from: date)
                grid[col][row] = countMap[key] ?? 0
            }
        }
        return grid
    }
}

struct ProjectViewPreference: View {
    @Binding var selection: String

    private struct Option: Identifiable {
        let id: String
        let label: String
        var value: String {
            id
        }
    }

    private let options: [Option] = [
        Option(id: ProjectViewStyle.cards.rawValue, label: "Cards"),
        Option(id: ProjectViewStyle.list.rawValue, label: "List"),
        Option(id: ProjectViewStyle.grid.rawValue, label: "Grid"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project View")
                .font(.headline)

            HStack(spacing: 0) {
                ForEach(options) { option in
                    let isSelected = selection == option.value
                    Button {
                        selection = option.value
                    } label: {
                        Text(option.label)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.primary.opacity(0.12) : Color.clear)
                            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
