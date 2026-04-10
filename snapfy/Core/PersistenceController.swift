import Foundation
import SwiftData

enum PersistenceController {
    static let shared: ModelContainer = {
        let schema = Schema([MediaEntry.self, UserAccount.self, WorkspaceRecord.self, WorkspaceMemberRecord.self])
        let storeURL = applicationSupportDirectory.appendingPathComponent("MediaCalendar.store")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-reset-store") {
            resetStoreIfNeeded(at: storeURL)
        }
        #endif

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            resetStoreIfNeeded(at: storeURL)

            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("SwiftData 저장소를 초기화하지 못했습니다: \(error.localizedDescription)")
            }
        }
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
