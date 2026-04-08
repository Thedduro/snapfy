import Foundation
import SwiftData

@Model
final class MediaEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var imageData: Data
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        imageData: Data,
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.imageData = imageData
        self.createdAt = createdAt
    }
}
