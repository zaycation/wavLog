import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            switch appState.authRoute {
            case .splash:
                SplashView()
            case .inviteGate:
                InviteGateView()
            case .signIn:
                SignInView()
            case .onboarding:
                OnboardingView()
            case .app:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.authRoute)
    }
}

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            VStack(spacing: 16) {
                AnimatedWaveformView()
                    .frame(height: 100)
                    .padding(.horizontal, 32)
                Text("WavLog")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.primary)
            }
        }
    }

    private var backgroundColor: Color {
        #if os(iOS)
        return colorScheme == .dark ? .black : Color(.systemBackground)
        #else
        return colorScheme == .dark ? .black : Color(nsColor: .windowBackgroundColor)
        #endif
    }
}

struct MainTabView: View {
    var body: some View {
        #if os(iOS)
        TabView {
            ProjectListView()
                .tabItem { Label("Projects", systemImage: "music.note.list") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
        }
        #else
        NavigationSplitView {
            SidebarView()
        } detail: {
            ProjectListView()
        }
        #endif
    }
}

#if os(macOS)
struct SidebarView: View {
    var body: some View {
        List {
            NavigationLink(destination: ProjectListView()) {
                Label("Projects", systemImage: "music.note.list")
            }
            NavigationLink(destination: ProfileView()) {
                Label("Profile", systemImage: "person.circle")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("WavLog")
    }
}
#endif
