import SwiftUI
import SwiftData

@main
struct snapfyApp: App {
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionStore)
        }
        .modelContainer(PersistenceController.shared)
    }
}
