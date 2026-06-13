import SwiftUI

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

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Untitled Beat", text: $title)
                        .focused($titleFocused)
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
        }
    }

    private func save() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            let draft = ProjectDraft(
                title: title.trimmingCharacters(in: .whitespaces),
                bpm: Int(bpmText),
                key: selectedKey == "None" ? nil : selectedKey,
                genre: selectedGenre,
                influences: influences.isEmpty ? nil : influences,
                bandlabURL: bandlabURL.isEmpty ? nil : bandlabURL
            )
            let project = try await ProjectService.shared.createProject(draft)
            onCreated?(project)
            dismiss()
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
