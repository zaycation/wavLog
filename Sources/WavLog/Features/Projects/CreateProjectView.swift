import SwiftUI

struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var bpmText = ""
    @State private var key = ""
    @State private var genre = ""
    @State private var influences = ""
    @State private var bandlabURL = ""
    @State private var isSubmitting = false

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Untitled Beat", text: $title)
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
                    HStack {
                        Text("Key")
                        Spacer()
                        TextField("e.g. Am", text: $key)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Genre")
                        Spacer()
                        TextField("e.g. Trap", text: $genre)
                            .multilineTextAlignment(.trailing)
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
            }
            .navigationTitle("New Project")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!canSubmit || isSubmitting)
                }
            }
        }
    }

    private func save() async {
        isSubmitting = true
        defer { isSubmitting = false }
        // TODO: call ProjectService to create project in Supabase
        dismiss()
    }
}

#Preview {
    CreateProjectView()
}
