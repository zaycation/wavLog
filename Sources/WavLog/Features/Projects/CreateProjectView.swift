import SwiftUI
import UniformTypeIdentifiers

struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    var onCreated: ((Project) -> Void)?

    @State private var title = ""
    @State private var bpmText = ""
    @State private var selectedKey: String? = nil
    @State private var selectedGenre: String? = nil
    @State private var influences = ""
    @State private var bandlabURL = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showKeyPicker = false
    @State private var showGenrePicker = false
    @FocusState private var titleFocused: Bool

    // Music Understanding auto-analysis (iOS 27+ / macOS 27+). See PRD 5.6.
    @State private var showAudioPicker = false
    @State private var pickedAudioURL: URL?
    @State private var isAnalyzing = false
    @State private var createdProject: Project?

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

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
                Section("Title") {
                    TextField("Untitled Beat", text: $title)
                        .focused($titleFocused)
                }

                if #available(iOS 27.0, macOS 27.0, *) {
                    Section {
                        Button {
                            showAudioPicker = true
                        } label: {
                            HStack {
                                Label(
                                    pickedAudioURL?.lastPathComponent ?? "Add Bounce (.wav or .m4a)",
                                    systemImage: pickedAudioURL != nil ? "waveform" : "doc.badge.plus"
                                )
                                Spacer()
                                if pickedAudioURL != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .disabled(isAnalyzing)
                    } header: {
                        Text("Audio Bounce")
                    } footer: {
                        Text("On-device analysis fills in BPM, key, and the waveform automatically.")
                    }
                }

                Section("Metadata") {
                    HStack {
                        Text("BPM")
                        Spacer()
                        TextField("e.g. 140", text: $bpmText)
                            .multilineTextAlignment(.trailing)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                    }

                    Button {
                        showKeyPicker = true
                    } label: {
                        HStack {
                            Text("Key")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(selectedKey ?? "Select")
                                .foregroundStyle(selectedKey == nil ? .secondary : .primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        showGenrePicker = true
                    } label: {
                        HStack {
                            Text("Genre")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(selectedGenre ?? "Select")
                                .foregroundStyle(selectedGenre == nil ? .secondary : .primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("References & Vibes") {
                    TextField(
                        "Artists, tracks, moods...",
                        text: $influences,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                Section("Links") {
                    TextField("BandLab URL", text: $bandlabURL)
                        #if os(iOS)
                        .keyboardType(.URL)
                        #endif
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Project")
            .onAppear { titleFocused = true }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await save() }
                        }
                        .disabled(!canSubmit)
                    }
                }
            }
            .sheet(isPresented: $showKeyPicker) {
                WheelPickerSheet(
                    title: "Key",
                    items: MusicMetadata.keys,
                    selection: $selectedKey
                )
            }
            .sheet(isPresented: $showGenrePicker) {
                WheelPickerSheet(
                    title: "Genre",
                    items: MusicMetadata.genres,
                    selection: $selectedGenre
                )
            }
            .fileImporter(
                isPresented: $showAudioPicker,
                allowedContentTypes: [
                    UTType(filenameExtension: "wav") ?? .audio,
                    UTType(filenameExtension: "m4a") ?? .audio,
                ],
                allowsMultipleSelection: false
            ) { result in
                guard case let .success(urls) = result, let url = urls.first else { return }
                Task { await handleAudioPicked(url) }
            }
        }
    }

    private func currentDraft() -> ProjectDraft {
        ProjectDraft(
            title: title.trimmingCharacters(in: .whitespaces),
            bpm: Int(bpmText),
            key: selectedKey == "None" ? nil : selectedKey,
            genre: selectedGenre,
            influences: influences.isEmpty ? nil : influences,
            bandlabURL: bandlabURL.isEmpty ? nil : bandlabURL
        )
    }

    private func save() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            let project: Project
            if let createdProject {
                project = try await ProjectService.shared.updateMetadata(createdProject, draft: currentDraft())
            } else {
                project = try await ProjectService.shared.createProject(currentDraft())
            }
            onCreated?(project)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Runs Music Understanding on the picked bounce, uploads it, and prefills
    /// metadata the user hasn't already entered. iOS 27+ / macOS 27+ only.
    private func handleAudioPicked(_ url: URL) async {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            title = url.deletingPathExtension().lastPathComponent
        }
        errorMessage = nil
        pickedAudioURL = url
        isAnalyzing = true
        defer { isAnalyzing = false }

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            let project: Project
            if let createdProject {
                project = createdProject
            } else {
                project = try await ProjectService.shared.createProject(currentDraft())
                createdProject = project
            }

            let result = try await MusicUnderstandingService.shared.analyze(audioURL: url)
            _ = try await BounceService.shared.uploadBounce(
                projectID: project.id,
                fileURL: url,
                versionNote: nil
            )

            if bpmText.isEmpty, let bpm = result.bpm {
                bpmText = String(bpm)
            }
            if selectedKey == nil, let key = result.key {
                selectedKey = key
            }
            createdProject = try await ProjectService.shared.updateDetectedMetadata(
                projectID: project.id,
                result: result
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct WheelPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let items: [String]
    @Binding var selection: String?

    @State private var current: String

    init(title: String, items: [String], selection: Binding<String?>) {
        self.title = title
        self.items = items
        self._selection = selection
        self._current = State(initialValue: selection.wrappedValue ?? items[0])
    }

    var body: some View {
        NavigationStack {
            Picker(title, selection: $current) {
                ForEach(items, id: \.self) { item in
                    Text(item).tag(item)
                }
            }
            .pickerStyle(.wheel)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        selection = nil
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selection = current
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    CreateProjectView()
}
