import ImageIO
import SwiftUI
import UIKit

struct LaunchIntroView: View {
    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width * 0.94, 430)

            Color.white.ignoresSafeArea()

            AnimatedGIFView(resourceName: "snapfy_anime")
                .frame(width: width, height: width * 9 / 16)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }
}

private struct AnimatedGIFView: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.clipsToBounds = true

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage.animatedGIF(named: resourceName)
        imageView.startAnimating()
        container.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        guard let imageView = container.subviews.first as? UIImageView else { return }
        if imageView.image == nil {
            imageView.image = UIImage.animatedGIF(named: resourceName)
        }
        imageView.startAnimating()
    }
}

private extension UIImage {
    static func animatedGIF(named name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: TimeInterval = 0

        for index in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }
            images.append(UIImage(cgImage: cgImage))
            duration += source.frameDuration(at: index)
        }

        return UIImage.animatedImage(with: images, duration: duration)
    }
}

private extension CGImageSource {
    func frameDuration(at index: Int) -> TimeInterval {
        let defaultDuration = 0.1
        guard let properties = CGImageSourceCopyPropertiesAtIndex(self, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return defaultDuration
        }

        let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let delay = unclampedDelay ?? gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval ?? defaultDuration

        return delay < 0.02 ? defaultDuration : delay
    }
}

#Preview {
    LaunchIntroView()
}
