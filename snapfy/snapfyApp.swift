import SwiftUI
import SwiftData

@main
struct snapfyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(PersistenceController.shared)
    }
}
