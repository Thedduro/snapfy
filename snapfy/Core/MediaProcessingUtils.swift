import AVFoundation
import UIKit

enum MediaProcessingUtils {
    static func imageData(from image: UIImage, compressionQuality: CGFloat = 0.9) -> Data? {
        image.jpegData(compressionQuality: compressionQuality)
    }

    static func thumbnailData(from image: UIImage, maxPixelSize: CGFloat = 320) -> Data? {
        let longestEdge = max(image.size.width, image.size.height)
        guard longestEdge > 0 else { return nil }

        let scale = min(1, maxPixelSize / longestEdge)
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return thumbnail.jpegData(compressionQuality: 0.8)
    }

    static func videoData(from url: URL) -> Data? {
        try? Data(contentsOf: url)
    }

    static func videoThumbnailData(from url: URL) -> Data? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 480)

        guard let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) else {
            return nil
        }

        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.8)
    }

    static func temporaryVideoURL(from data: Data, id: UUID) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("snapfy-\(id.uuidString)")
            .appendingPathExtension("mov")

        do {
            if FileManager.default.fileExists(atPath: url.path()) {
                try FileManager.default.removeItem(at: url)
            }
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
