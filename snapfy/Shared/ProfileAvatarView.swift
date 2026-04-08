import SwiftUI
import UIKit

struct ProfileAvatarView: View {
    let imageData: Data?
    let size: CGFloat

    var body: some View {
        avatarImage
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
    }

    private var avatarImage: Image {
        guard let imageData,
              let uiImage = UIImage(data: imageData) else {
            return Image("DefaultProfileImage")
        }

        return Image(uiImage: uiImage)
    }
}

#Preview {
    ProfileAvatarView(imageData: nil, size: 96)
}
