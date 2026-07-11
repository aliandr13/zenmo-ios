import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthStore

    var body: some View {
        if auth.isRestoring {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if auth.isAuthenticated {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                Text("Dashboard — coming soon")
                    .navigationTitle("Dashboard")
            }
            .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }

            NavigationStack {
                Text("Accounts — coming soon")
                    .navigationTitle("Accounts")
            }
            .tabItem { Label("Accounts", systemImage: "creditcard.fill") }

            NavigationStack {
                Text("Transactions — coming soon")
                    .navigationTitle("Transactions")
            }
            .tabItem { Label("Transactions", systemImage: "arrow.left.arrow.right") }

            NavigationStack {
                Text("Categories — coming soon")
                    .navigationTitle("Categories")
            }
            .tabItem { Label("Categories", systemImage: "tag.fill") }

            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var auth: AuthStore

    var body: some View {
        List {
            if let user = auth.currentUser {
                Section("Account") {
                    LabeledContent("Email", value: user.email)
                }
            }
            Section {
                Button("Log out", role: .destructive) {
                    Task { await auth.logout() }
                }
            }
        }
    }
}
