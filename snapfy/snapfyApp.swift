import FirebaseCore
import SwiftUI
import SwiftData

@main
struct snapfyApp: App {
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var workspaceStore = WorkspaceStore()

    init() {
        FirebaseBootstrap.configureIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionStore)
                .environmentObject(workspaceStore)
                .onOpenURL { url in
                    guard let userID = sessionStore.currentUser?.id else { return }
                    try? workspaceStore.handleIncomingURL(url, userID: userID)
                }
        }
        .modelContainer(PersistenceController.shared)
    }
}
