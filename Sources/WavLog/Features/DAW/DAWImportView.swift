import SwiftUI
import UniformTypeIdentifiers

// macOS only — shown when user drops a DAW project file onto the app
#if os(macOS)
struct DAWDropOverlay: View {
    @Binding var isTargeted: Bool

    var body: some View {
        Group {
            if isTargeted {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.purple, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.purple.opacity(0.08))
                    )
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.purple)
                            Text("Drop to import project")
                                .font(.headline)
                                .foregroundStyle(.purple)
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .animation(.easeOut(duration: 0.15), value: isTargeted)
            }
        }
    }
}

struct DAWImportReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let result: DAWImportResult
    var onConfirm: ((ProjectDraft) -> Void)?

    @State private var title: String
    @State private var bpmText: String
    @State private var selectedKey: String?
    @State private var selectedGenre: String? = nil
    @State private var showKeyPicker = false

    init(result: DAWImportResult, onConfirm: ((ProjectDraft) -> Void)?) {
        self.result = result
        self.onConfirm = onConfirm
        self._title = State(initialValue: result.title ?? "")
        self._bpmText = State(initialValue: result.bpm.map(String.init) ?? "")
        self._selectedKey = State(initialValue: result.key)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Imported from \(result.format.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Title") {
                    TextField("Untitled Beat", text: $title)
                }

                Section("Extracted Metadata") {
                    HStack {
                        Text("BPM")
                        Spacer()
                        TextField("e.g. 140", text: $bpmText)
                            .multilineTextAlignment(.trailing)
                    }

                    Button {
                        showKeyPicker = true
                    } label: {
                        HStack {
                            Text("Key").foregroundStyle(.primary)
                            Spacer()
                            Text(selectedKey ?? "Select")
                                .foregroundStyle(selectedKey == nil ? .secondary : .primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Fields that couldn't be extracted are left blank. The project file is never uploaded or stored.")
                }
            }
            .navigationTitle("Review Import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create Project") {
                        let draft = ProjectDraft(
                            title: title.isEmpty ? "Untitled Beat" : title,
                            bpm: Int(bpmText),
                            key: selectedKey == "None" ? nil : selectedKey,
                            genre: selectedGenre,
                            influences: nil,
                            bandlabURL: nil
                        )
                        onConfirm?(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showKeyPicker) {
                WheelPickerSheet(
                    title: "Key",
                    items: MusicMetadata.keys,
                    selection: $selectedKey
                )
            }
        }
        .frame(minWidth: 420, minHeight: 360)
    }
}
#endif
