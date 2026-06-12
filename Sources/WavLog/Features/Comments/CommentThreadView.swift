import SwiftUI

struct CommentThreadView: View {
    let projectID: String
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if comments.isEmpty {
                        Text("No feedback yet.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        ForEach(comments) { comment in
                            CommentRowView(comment: comment)
                        }
                    }
                }
                .padding()
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Leave feedback...", text: $newCommentText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button {
                    Task { await submitComment() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
    }

    private func submitComment() async {
        // TODO: call CommentService
        newCommentText = ""
    }
}

struct CommentRowView: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(comment.authorID)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text(comment.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if comment.isResolved {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            Text(comment.body)
                .font(.subheadline)
        }
        .padding()
        .background(.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(comment.isResolved ? 0.5 : 1)
    }
}

#Preview {
    CommentThreadView(projectID: "preview")
}
