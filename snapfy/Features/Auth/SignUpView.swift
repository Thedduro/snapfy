import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    @State private var displayName = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    ProfileAvatarView(imageData: nil, size: 64)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("닉네임")
                            .font(.subheadline.weight(.semibold))
                        TextField("닉네임", text: $displayName)
                            .padding(14)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button {
                        signUp()
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("바로 시작하기")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 14))
                    .disabled(isSubmitting)
                }
                .padding(20)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func signUp() {
        errorMessage = nil
        isSubmitting = true

        defer {
            isSubmitting = false
        }

        do {
            try sessionStore.signUp(
                SignUpPayload(displayName: displayName)
            )
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AuthError.unknown.errorDescription
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(SessionStore())
}
