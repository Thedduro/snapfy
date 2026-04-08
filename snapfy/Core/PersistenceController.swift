import Foundation
import SwiftData

enum PersistenceController {
    static let shared: ModelContainer = {
        let schema = Schema([MediaEntry.self, UserAccount.self])
        let storeURL = applicationSupportDirectory.appendingPathComponent("MediaCalendar.store")

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-reset-store") {
            resetStoreIfNeeded(at: storeURL)
        }
        #endif

        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    private static var applicationSupportDirectory: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func resetStoreIfNeeded(at storeURL: URL) {
        let fileManager = FileManager.default
        let relatedURLs = [
            storeURL,
            storeURL.appendingPathExtension("sqlite"),
            storeURL.appendingPathExtension("sqlite-shm"),
            storeURL.appendingPathExtension("sqlite-wal")
        ]

        for url in relatedURLs where fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
}
