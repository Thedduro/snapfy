import SwiftUI
import WebKit

struct FirstLoginIntroView: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                GIFPlayerView(resourceName: "snapfy_anime")
                    .frame(width: 320, height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

                Button {
                    onFinish()
                } label: {
                    Text("시작하기")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.16))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

private struct GIFPlayerView: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isUserInteractionEnabled = false
        loadGIF(into: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url == nil else { return }
        loadGIF(into: webView)
    }

    private func loadGIF(into webView: WKWebView) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "gif") else {
            return
        }

        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}

#Preview {
    FirstLoginIntroView(onFinish: {})
}
