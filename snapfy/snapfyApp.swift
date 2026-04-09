import SwiftUI
import SwiftData

@main
struct snapfyApp: App {
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var workspaceStore = WorkspaceStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionStore)
                .environmentObject(workspaceStore)
        }
        .modelContainer(PersistenceController.shared)
    }
}
