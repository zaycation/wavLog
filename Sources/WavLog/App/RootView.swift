import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        #if os(iOS)
        TabView {
            ProjectListView()
                .tabItem {
                    Label("Projects", systemImage: "music.note.list")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
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
