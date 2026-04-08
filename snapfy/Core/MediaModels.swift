import Foundation
import SwiftData

@Model
final class MediaEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var imageData: Data?
    var videoData: Data?
    var thumbnailData: Data
    var mediaType: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        imageData: Data? = nil,
        videoData: Data? = nil,
        thumbnailData: Data,
        mediaType: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.imageData = imageData
        self.videoData = videoData
        self.thumbnailData = thumbnailData
        self.mediaType = mediaType
        self.createdAt = createdAt
    }
}
