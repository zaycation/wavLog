import SwiftUI
import UniformTypeIdentifiers

struct BounceHistoryView: View {
    @Binding var project: Project
    @State private var bounces: [Bounce] = []
    @State private var isLoading = false
    @State private var showUploadSheet = false
    @State private var errorMessage: String?
    @State private var activeBounceID: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Bounce History")
                    .font(.headline)
                    .padding()
                Spacer()
                Button {
                    showUploadSheet = true
                } label: {
                    Label("Upload", systemImage: "arrow.up.circle")
                        .font(.subheadline)
                }
                .padding()
                .disabled(project.isArchived)
            }
            Divider()

            if isLoading && bounces.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if bounces.isEmpty {
                ContentUnavailableView(
                    "No Bounces Yet",
                    systemImage: "waveform",
                    description: Text("Upload a .wav or .m4a to start the history.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(bounces.enumerated()), id: \.element.id) { index, bounce in
                            BounceRowView(
                                bounce: bounce,
                                isLatest: index == 0,
                                waveform: index == 0 ? project.waveformData : nil,
                                activeBounceID: $activeBounceID
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .task { await loadBounces() }
        .sheet(isPresented: $showUploadSheet) {
            UploadBounceView(
                projectID: project.id,
                onUploaded: { newBounce in
                    bounces.insert(newBounce, at: 0)
                },
                onProjectUpdated: { updated in
                    project = updated
                }
            )
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadBounces() async {
        isLoading = true
        defer { isLoading = false }
        do {
            bounces = try await BounceService.shared.fetchBounces(projectID: project.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct BounceRowView: View {
    let bounce: Bounce
    let isLatest: Bool
    var waveform: [Double]?
    @Binding var activeBounceID: String?
    @State private var signedURL: URL?
    @State private var isLoadingURL = false
    @State private var uploaderName: String = "..."

    private var isActive: Bool {
        activeBounceID == bounce.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        if isLatest {
                            Text("LATEST")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                        Text(uploaderName)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(bounce.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(bounce.createdAt, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let note = bounce.versionNote, !note.isEmpty {
                        Text(note)
                            .font(.subheadline)
                    }
                }
                Spacer()
            }

            if isActive, let url = signedURL {
                AudioPlayerView(url: url, waveform: waveform)
            } else {
                Button {
                    Task { await loadAndPlay() }
                } label: {
                    Label(
                        isLoadingURL ? "Loading..." : "Load Audio",
                        systemImage: "play.circle"
                    )
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isLoadingURL)
            }
        }
        .padding()
        .background(.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            uploaderName = await ProfileCache.shared.displayName(for: bounce.uploaderID)
        }
    }

    private func loadAndPlay() async {
        isLoadingURL = true
        defer { isLoadingURL = false }
        if signedURL == nil {
            signedURL = try? await BounceService.shared.signedURL(for: bounce)
        }
        if signedURL != nil {
            activeBounceID = bounce.id
        }
    }
}

struct UploadBounceView: View {
    @Environment(\.dismiss) private var dismiss
    let projectID: String
    var onUploaded: ((Bounce) -> Void)?
    var onProjectUpdated: ((Project) -> Void)?

    @State private var selectedFileURL: URL?
    @State private var versionNote = ""
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var errorMessage: String?
    @State private var showFilePicker = false
    @State private var isAnalyzing = false

    var body: some View {
        ZStack {
            navigationContent

            if isAnalyzing {
                AnalyzingBounceView()
            }
        }
    }

    private var navigationContent: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showFilePicker = true
                    } label: {
                        HStack {
                            Label(
                                selectedFileURL?.lastPathComponent ?? "Choose File (.wav or .m4a)",
                                systemImage: selectedFileURL != nil ? "waveform" : "doc.badge.plus"
                            )
                            Spacer()
                            if selectedFileURL != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                } header: {
                    Text("Audio File")
                } footer: {
                    Text("Max 100 MB. .wav and .m4a only.")
                }

                Section("Version Note (optional)") {
                    TextField(
                        "e.g. tightened the drums, new 808 on the drop",
                        text: $versionNote,
                        axis: .vertical
                    )
                    .lineLimit(2 ... 4)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Upload Bounce")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if isUploading {
                            ProgressView()
                        } else {
                            Button("Upload") {
                                Task { await upload() }
                            }
                            .disabled(selectedFileURL == nil)
                        }
                    }
                }
                .fileImporter(
                    isPresented: $showFilePicker,
                    allowedContentTypes: [
                        UTType(filenameExtension: "wav") ?? .audio,
                        UTType(filenameExtension: "m4a") ?? .audio,
                    ],
                    allowsMultipleSelection: false
                ) { result in
                    Task { @MainActor in
                        guard case let .success(urls) = result, let url = urls.first else { return }
                        selectedFileURL = url
                        if versionNote.isEmpty {
                            versionNote = url.deletingPathExtension().lastPathComponent
                        }
                    }
                }
        }
    }

    private func upload() async {
        guard let fileURL = selectedFileURL else { return }
        isUploading = true
        errorMessage = nil
        defer { isUploading = false }

        // Gain security-scoped access for file picker URLs
        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessing { fileURL.stopAccessingSecurityScopedResource() }
        }

        do {
            let bounce = try await BounceService.shared.uploadBounce(
                projectID: projectID,
                fileURL: fileURL,
                versionNote: versionNote.isEmpty ? nil : versionNote
            )
            onUploaded?(bounce)
            await analyzeIfSupported(fileURL: fileURL)
            dismiss()
        } catch {
            print("BOUNCE UPLOAD ERROR: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    /// Re-runs Music Understanding on every new bounce, not just the first
    /// (PRD 5.6 / 8): each version gets its own auto-extracted BPM and key.
    private func analyzeIfSupported(fileURL: URL) async {
        guard #available(iOS 27.0, macOS 27.0, *) else { return }
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            let result = try await MusicUnderstandingService.shared.analyze(audioURL: fileURL)
            let updated = try await ProjectService.shared.updateDetectedMetadata(
                projectID: projectID,
                result: result
            )
            onProjectUpdated?(updated)
        } catch {
            print("MUSIC UNDERSTANDING ERROR: \(error)")
        }
    }
}
