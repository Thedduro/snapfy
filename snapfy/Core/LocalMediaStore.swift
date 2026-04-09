import Foundation
import SwiftData
import UIKit

protocol MediaStore {
    func entries(
        for day: Date,
        workspaceID: UUID?,
        in mediaEntries: [MediaEntry]
    ) -> [MediaEntry]

    func saveImage(
        _ image: UIImage,
        for date: Date,
        workspaceID: UUID,
        context: ModelContext
    ) throws

    func saveVideo(
        _ url: URL,
        for date: Date,
        workspaceID: UUID,
        context: ModelContext
    ) throws
}

struct LocalMediaStore: MediaStore {
    func entries(
        for day: Date,
        workspaceID: UUID?,
        in mediaEntries: [MediaEntry]
    ) -> [MediaEntry] {
        guard let workspaceID else {
            return []
        }

        return mediaEntries.filter {
            $0.workspaceID == workspaceID && CalendarDateUtils.isSameDay($0.date, day)
        }
    }

    func saveImage(
        _ image: UIImage,
        for date: Date,
        workspaceID: UUID,
        context: ModelContext
    ) throws {
        guard let imageData = MediaProcessingUtils.imageData(from: image),
              let thumbnailData = MediaProcessingUtils.thumbnailData(from: image) else {
            return
        }

        let entry = MediaEntry(
            workspaceID: workspaceID,
            date: date,
            imageData: imageData,
            thumbnailData: thumbnailData,
            mediaType: "image"
        )

        context.insert(entry)
        try context.save()
    }

    func saveVideo(
        _ url: URL,
        for date: Date,
        workspaceID: UUID,
        context: ModelContext
    ) throws {
        guard let videoData = MediaProcessingUtils.videoData(from: url),
              let thumbnailData = MediaProcessingUtils.videoThumbnailData(from: url) else {
            return
        }

        let entry = MediaEntry(
            workspaceID: workspaceID,
            date: date,
            videoData: videoData,
            thumbnailData: thumbnailData,
            mediaType: "video"
        )

        context.insert(entry)
        try context.save()
    }
}
