import Foundation
import SwiftData

enum PersistenceController {
    static let shared: ModelContainer = {
        let schema = Schema([MediaEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
}
