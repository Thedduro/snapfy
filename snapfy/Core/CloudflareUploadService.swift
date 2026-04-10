import Foundation
import UIKit

enum CloudflareUploadError: LocalizedError {
    case invalidWorkerURL
    case invalidUploadResponse(String)
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidWorkerURL:
            return "업로드 서버 주소를 확인할 수 없습니다."
        case .invalidUploadResponse(let reason):
            return "업로드 URL 응답이 올바르지 않습니다. \(reason)"
        case .uploadFailed(let reason):
            return "Cloudflare 업로드에 실패했습니다. \(reason)"
        }
    }
}

struct ImageUploadTicket: Decodable {
    let uploadURL: String
    let imageID: String
    let originalURL: String
    let thumbnailURL: String

    enum CodingKeys: String, CodingKey {
        case uploadURL
        case uploadUrl
        case imageID
        case imageId
        case id
        case originalURL
        case originalUrl
        case thumbnailURL
        case thumbnailUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uploadURL = try container.decodeFirstString(forKeys: [.uploadURL, .uploadUrl])
        imageID = try container.decodeFirstString(forKeys: [.imageID, .imageId, .id])
        originalURL = try container.decodeFirstString(forKeys: [.originalURL, .originalUrl])
        thumbnailURL = try container.decodeFirstString(forKeys: [.thumbnailURL, .thumbnailUrl])
    }
}

struct VideoUploadTicket: Decodable {
    let uploadURL: String
    let uid: String
    let streamURL: String
    let thumbnailURL: String

    enum CodingKeys: String, CodingKey {
        case uploadURL
        case uploadUrl
        case uid
        case id
        case streamURL
        case streamUrl
        case playbackURL
        case playbackUrl
        case thumbnailURL
        case thumbnailUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uploadURL = try container.decodeFirstString(forKeys: [.uploadURL, .uploadUrl])
        uid = try container.decodeFirstString(forKeys: [.uid, .id])
        streamURL = try container.decodeFirstString(forKeys: [.streamURL, .streamUrl, .playbackURL, .playbackUrl])
        thumbnailURL = try container.decodeFirstString(forKeys: [.thumbnailURL, .thumbnailUrl])
    }
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

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudflareUploadError.invalidUploadResponse("HTTP 응답을 해석할 수 없습니다.")
        }

        let bodySnippet = responseSnippet(from: data)

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw CloudflareUploadError.invalidUploadResponse("HTTP \(httpResponse.statusCode), 응답: \(bodySnippet)")
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw CloudflareUploadError.invalidUploadResponse("JSON 파싱 실패, 응답: \(bodySnippet)")
        }
    }

    private func upload(data: Data, filename: String, mimeType: String, uploadURL: String) async throws {
        guard let url = URL(string: uploadURL) else {
            throw CloudflareUploadError.invalidUploadResponse("uploadURL 형식이 올바르지 않습니다.")
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

        request.httpBody = body
        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudflareUploadError.uploadFailed("HTTP 응답을 해석할 수 없습니다.")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw CloudflareUploadError.uploadFailed("HTTP \(httpResponse.statusCode), 응답: \(responseSnippet(from: responseData))")
        }
    }

    private func responseSnippet(from data: Data, maxLength: Int = 240) -> String {
        guard !data.isEmpty else { return "(empty)" }
        let text = String(decoding: data, as: UTF8.self)
        return text.count > maxLength ? String(text.prefix(maxLength)) + "..." : text
    }
}

private extension KeyedDecodingContainer {
    func decodeFirstString(forKeys keys: [K]) throws -> String {
        for key in keys {
            if let value = try decodeIfPresent(String.self, forKey: key),
               !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }

        let keysText = keys.map(\.stringValue).joined(separator: ", ")
        throw DecodingError.keyNotFound(
            keys[0],
            DecodingError.Context(codingPath: codingPath, debugDescription: "Missing one of keys: \(keysText)")
        )
    }
}
