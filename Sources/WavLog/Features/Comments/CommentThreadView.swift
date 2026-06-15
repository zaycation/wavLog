import SwiftUI

struct CommentThreadView: View {
    let projectID: String
    @EnvironmentObject private var appState: AppState
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var replyingTo: Comment?
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var topLevel: [Comment] {
        comments.filter { $0.parentID == nil }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if isLoading && comments.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if comments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary.opacity(0.5))
                            Text("No feedback yet")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Be the first to drop a note or reaction on this project.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        ForEach(topLevel) { comment in
                            CommentRowView(
                                comment: comment,
                                replies: comments.filter { $0.parentID == comment.id },
                                currentUserID: appState.currentUser?.id,
                                onReply: { replyingTo = comment },
                                onResolve: { Task { await resolve(comment) } }
                            )
                        }
                    }
                }
                .padding()
            }

            Divider()

            if let parent = replyingTo {
                HStack {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Replying to: \(parent.body.prefix(40))...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        replyingTo = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            HStack(spacing: 12) {
                TextField("Leave feedback...", text: $newCommentText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1 ... 4)
                Button {
                    Task { await submitComment() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(
                    newCommentText.trimmingCharacters(in: .whitespaces).isEmpty
                        || isSubmitting
                )
            }
            .padding()
        }
        .task { await loadComments() }
    }

    private func loadComments() async {
        isLoading = true
        defer { isLoading = false }
        do {
            comments = try await CommentService.shared.fetchComments(projectID: projectID)
            await ProfileCache.shared.prefetch(userIDs: comments.map(\.authorID))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submitComment() async {
        let body = newCommentText.trimmingCharacters(in: .whitespaces)
        guard !body.isEmpty else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let comment = try await CommentService.shared.postComment(
                projectID: projectID,
                body: body,
                parentID: replyingTo?.id
            )
            comments.append(comment)
            newCommentText = ""
            replyingTo = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolve(_ comment: Comment) async {
        guard let updated = try? await CommentService.shared.resolveComment(comment) else { return }
        if let idx = comments.firstIndex(where: { $0.id == comment.id }) {
            comments[idx] = updated
        }
    }
}

struct CommentRowView: View {
    let comment: Comment
    let replies: [Comment]
    let currentUserID: String?
    let onReply: () -> Void
    let onResolve: () -> Void

    @State private var showReplies = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SingleCommentView(
                comment: comment,
                currentUserID: currentUserID,
                onReply: onReply,
                onResolve: onResolve
            )

            if !replies.isEmpty {
                Button {
                    showReplies.toggle()
                } label: {
                    Label(
                        showReplies ? "Hide replies" : "\(replies.count) repl\(replies.count == 1 ? "y" : "ies")",
                        systemImage: showReplies ? "chevron.up" : "chevron.down"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.leading, 16)

                if showReplies {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(replies) { reply in
                            SingleCommentView(
                                comment: reply,
                                currentUserID: currentUserID,
                                onReply: onReply,
                                onResolve: {}
                            )
                        }
                    }
                    .padding(.leading, 16)
                }
            }
        }
    }
}

struct SingleCommentView: View {
    let comment: Comment
    let currentUserID: String?
    let onReply: () -> Void
    let onResolve: () -> Void
    @State private var authorName: String = "..."

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(authorName)
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

            if !comment.isResolved {
                HStack(spacing: 16) {
                    Button("Reply", action: onReply)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if currentUserID != nil {
                        Button("Resolve", action: onResolve)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(comment.isResolved ? 0.5 : 1)
        .task {
            authorName = await ProfileCache.shared.displayName(for: comment.authorID)
        }
    }
}

#Preview {
    CommentThreadView(projectID: "preview")
        .environmentObject(AppState())
}
