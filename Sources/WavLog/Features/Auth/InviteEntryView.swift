import SwiftUI

struct InviteEntryView: View {
    @Environment(\.dismiss) private var dismiss
    var onValidated: ((String) -> Void)?

    @State private var code = ""
    @State private var isValidating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 48))
                        .foregroundStyle(.purple)
                    Text("Enter Invite Code")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("WavLog is invite-only. Enter your 8-character code to get started.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    TextField("XXXX-XXXX", text: $code)
                        .textCase(.uppercase)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .padding()
                        .background(.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: code) { _, newValue in
                            code = String(
                                newValue.uppercased()
                                    .filter { $0.isLetter || $0.isNumber }
                                    .prefix(8)
                            )
                        }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await validate() }
                    } label: {
                        Group {
                            if isValidating {
                                ProgressView().tint(.white)
                            } else {
                                Text("Continue")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(code.count == 8 ? Color.purple : Color.secondary.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(code.count != 8 || isValidating)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Invite Code")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func validate() async {
        isValidating = true
        errorMessage = nil
        defer { isValidating = false }
        do {
            try await InviteService.shared.validateCode(code)
            onValidated?(code.uppercased())
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    InviteEntryView()
}
