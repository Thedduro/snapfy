import FirebaseFirestore
import Foundation
import UIKit

enum FirestoreMediaError: LocalizedError {
    case imageEncodingFailed
    case videoEncodingFailed
    case missingThumbnail
    case invalidWorkspace
    case invalidUser

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed:
            return "이미지 데이터를 처리할 수 없습니다."
        case .videoEncodingFailed:
            return "영상 데이터를 처리할 수 없습니다."
        case .missingThumbnail:
            return "썸네일 생성에 실패했습니다."
        case .invalidWorkspace:
            return "워크스페이스 정보가 올바르지 않습니다."
        case .invalidUser:
            return "사용자 정보를 확인할 수 없습니다."
        }
    }
}

struct WorkspaceMediaItem: Identifiable, Equatable {
    let id: String
    let workspaceID: String
    let ownerUserID: String
    let date: Date
    let mediaType: String
    let originalURL: String
    let thumbnailURL: String
    let createdAt: Date
}

struct FirestoreMediaStore {
    private let firestore: Firestore
    private let uploadService: CloudflareUploadService

    init(
        firestore: Firestore = FirebaseBootstrap.firestore,
        uploadService: CloudflareUploadService = CloudflareUploadService()
    ) {
        self.firestore = firestore
        self.uploadService = uploadService
    }

    func entries(
        for day: Date,
        workspaceID: UUID?,
        in mediaEntries: [WorkspaceMediaItem]
    ) -> [WorkspaceMediaItem] {
        guard let workspaceID else {
            return []
        }

        return mediaEntries.filter {
            $0.workspaceID == workspaceID.uuidString && CalendarDateUtils.isSameDay($0.date, day)
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchMonthEntries(workspaceID: UUID, month: Date) async throws -> [WorkspaceMediaItem] {
        let workspaceIDString = workspaceID.uuidString
        let monthStart = CalendarDateUtils.startOfMonth(for: month)
        let nextMonthStart = CalendarDateUtils.calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart

        let query = firestore
            .collection("workspaces")
            .document(workspaceIDString)
            .collection("media")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: monthStart))
            .whereField("date", isLessThan: Timestamp(date: nextMonthStart))

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap(parseDocument).sorted { $0.createdAt > $1.createdAt }
    }

    func saveImage(
        _ image: UIImage,
        for date: Date,
        workspaceID: UUID,
        ownerUserID: UUID
    ) async throws -> WorkspaceMediaItem {
        guard let imageData = MediaProcessingUtils.imageData(from: image) else {
            throw FirestoreMediaError.imageEncodingFailed
        }

        let ticket = try await uploadService.requestImageTicket()
        try await uploadService.uploadImageData(imageData, to: ticket.uploadURL)

        return try await saveMetadata(
            workspaceID: workspaceID,
            ownerUserID: ownerUserID,
            date: date,
            mediaType: "image",
            originalURL: ticket.originalURL,
            thumbnailURL: ticket.thumbnailURL
        )
    }

    func saveVideo(
        _ url: URL,
        for date: Date,
        workspaceID: UUID,
        ownerUserID: UUID
    ) async throws -> WorkspaceMediaItem {
        guard let videoData = MediaProcessingUtils.videoData(from: url) else {
            throw FirestoreMediaError.videoEncodingFailed
        }

        guard MediaProcessingUtils.videoThumbnailData(from: url) != nil else {
            throw FirestoreMediaError.missingThumbnail
        }

        let ticket = try await uploadService.requestVideoTicket()
        let fileExtension = url.pathExtension.isEmpty ? "mov" : url.pathExtension
        try await uploadService.uploadVideoData(videoData, to: ticket.uploadURL, fileExtension: fileExtension)

        return try await saveMetadata(
            workspaceID: workspaceID,
            ownerUserID: ownerUserID,
            date: date,
            mediaType: "video",
            originalURL: ticket.streamURL,
            thumbnailURL: ticket.thumbnailURL
        )
    }

    private func saveMetadata(
        workspaceID: UUID,
        ownerUserID: UUID,
        date: Date,
        mediaType: String,
        originalURL: String,
        thumbnailURL: String
    ) async throws -> WorkspaceMediaItem {
        let workspaceIDString = workspaceID.uuidString
        let ownerUserIDString = ownerUserID.uuidString
        let startOfDay = CalendarDateUtils.calendar.startOfDay(for: date)
        let now = Date()

        let documentReference = firestore
            .collection("workspaces")
            .document(workspaceIDString)
            .collection("media")
            .document()

        let payload: [String: Any] = [
            "workspaceID": workspaceIDString,
            "ownerUserID": ownerUserIDString,
            "date": Timestamp(date: startOfDay),
            "mediaType": mediaType,
            "originalURL": originalURL,
            "thumbnailURL": thumbnailURL,
            "createdAt": Timestamp(date: now)
        ]

        try await documentReference.setData(payload)

        return WorkspaceMediaItem(
            id: documentReference.documentID,
            workspaceID: workspaceIDString,
            ownerUserID: ownerUserIDString,
            date: startOfDay,
            mediaType: mediaType,
            originalURL: originalURL,
            thumbnailURL: thumbnailURL,
            createdAt: now
        )
    }

    private func parseDocument(_ document: QueryDocumentSnapshot) -> WorkspaceMediaItem? {
        let data = document.data()

        guard let workspaceID = data["workspaceID"] as? String,
              let ownerUserID = data["ownerUserID"] as? String,
              let mediaType = data["mediaType"] as? String,
              let originalURL = data["originalURL"] as? String,
              let thumbnailURL = data["thumbnailURL"] as? String else {
            return nil
        }

        let date = (data["date"] as? Timestamp)?.dateValue() ?? .now
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .now

        return WorkspaceMediaItem(
            id: document.documentID,
            workspaceID: workspaceID,
            ownerUserID: ownerUserID,
            date: date,
            mediaType: mediaType,
            originalURL: originalURL,
            thumbnailURL: thumbnailURL,
            createdAt: createdAt
        )
    }
}
