import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ProfileHeaderView(user: appState.currentUser)
                    ActivityChartView()
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
    }
}

struct ProfileHeaderView: View {
    let user: UserProfile?

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(.secondary.opacity(0.2))
                .frame(width: 72, height: 72)
                .overlay {
                    if let avatarURL = user?.avatarURL {
                        AsyncImage(url: URL(string: avatarURL)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(user?.displayName ?? "Loading...")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
    }
}

struct ActivityChartView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)
            // TODO: GitHub-style contribution graph
            RoundedRectangle(cornerRadius: 8)
                .fill(.secondary.opacity(0.1))
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .overlay {
                    Text("Activity chart coming soon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
