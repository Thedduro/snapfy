import Foundation
import UIKit

enum CloudflareUploadError: LocalizedError {
    case invalidWorkerURL
    case invalidUploadResponse
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .invalidWorkerURL:
            return "업로드 서버 주소를 확인할 수 없습니다."
        case .invalidUploadResponse:
            return "업로드 URL 응답이 올바르지 않습니다."
        case .uploadFailed:
            return "Cloudflare 업로드에 실패했습니다."
        }
    }
}

struct ImageUploadTicket: Decodable {
    let uploadURL: String
    let imageID: String
    let originalURL: String
    let thumbnailURL: String
}

struct VideoUploadTicket: Decodable {
    let uploadURL: String
    let uid: String
    let streamURL: String
    let thumbnailURL: String
}

struct CloudflareUploadService {
    private let session: URLSession
    private let workerBaseURL: URL

    init(session: URLSession = .shared) {
        self.session = session
        self.workerBaseURL = URL(string: "https://snapfy-upload-api.lsw2207.workers.dev")!
    }

    func requestImageTicket() async throws -> ImageUploadTicket {
        try await requestTicket(
            path: "/images/direct-upload",
            type: ImageUploadTicket.self
        )
    }

    func requestVideoTicket() async throws -> VideoUploadTicket {
        try await requestTicket(
            path: "/stream/direct-upload",
            type: VideoUploadTicket.self
        )
    }

    func uploadImageData(_ data: Data, to uploadURL: String) async throws {
        try await upload(
            data: data,
            filename: "image.jpg",
            mimeType: "image/jpeg",
            uploadURL: uploadURL
        )
    }

    func uploadVideoData(_ data: Data, to uploadURL: String, fileExtension: String) async throws {
        let mimeType = fileExtension.lowercased() == "mp4" ? "video/mp4" : "video/quicktime"
        try await upload(
            data: data,
            filename: "video.\(fileExtension)",
            mimeType: mimeType,
            uploadURL: uploadURL
        )
    }

    private func requestTicket<T: Decodable>(path: String, type: T.Type) async throws -> T {
        guard let url = URL(string: path, relativeTo: workerBaseURL) else {
            throw CloudflareUploadError.invalidWorkerURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw CloudflareUploadError.invalidUploadResponse
        }

        return try JSONDecoder().decode(type, from: data)
    }

    private func upload(data: Data, filename: String, mimeType: String, uploadURL: String) async throws {
        guard let url = URL(string: uploadURL) else {
            throw CloudflareUploadError.invalidUploadResponse
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await session.upload(for: request, from: body)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw CloudflareUploadError.uploadFailed
        }
    }
}
