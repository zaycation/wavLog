import SwiftUI

struct InviteManagerView: View {
    @State private var invites: [Invite] = []
    @State private var isLoading = false
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var copiedCode: String?

    var body: some View {
        List {
            Section {
                Button {
                    Task { await generateInvite() }
                } label: {
                    HStack {
                        Label("Generate Invite Code", systemImage: "plus.circle.fill")
                            .foregroundStyle(.purple)
                        Spacer()
                        if isGenerating { ProgressView() }
                    }
                }
                .disabled(isGenerating)
            } footer: {
                Text("Share these codes with producers and artists you want to invite.")
            }

            if !invites.isEmpty {
                Section("Your Invites") {
                    ForEach(invites) { invite in
                        InviteRowView(
                            invite: invite,
                            isCopied: copiedCode == invite.code
                        ) {
                            copyCode(invite.code)
                        }
                    }
                }
            }
        }
        .navigationTitle("Invites")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await loadInvites() }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadInvites() async {
        isLoading = true
        defer { isLoading = false }
        invites = (try? await InviteService.shared.fetchMyInvites()) ?? []
    }

    private func generateInvite() async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            let invite = try await InviteService.shared.generateInvite()
            invites.insert(invite, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func copyCode(_ code: String) {
        #if os(iOS)
        UIPasteboard.general.string = code
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        #endif
        copiedCode = code
        Task {
            try? await Task.sleep(for: .seconds(2))
            if copiedCode == code { copiedCode = nil }
        }
    }
}

struct InviteRowView: View {
    let invite: Invite
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatCode(invite.code))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(invite.isUsed ? .secondary : .primary)

                if invite.isUsed {
                    Text("Used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Available")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            if !invite.isUsed {
                Button {
                    onCopy()
                } label: {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundStyle(isCopied ? .green : .secondary)
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private func formatCode(_ code: String) -> String {
        guard code.count == 8 else { return code }
        return "\(code.prefix(4))-\(code.suffix(4))"
    }
}

#Preview {
    NavigationStack {
        InviteManagerView()
    }
}
