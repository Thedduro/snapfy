import SwiftUI

private enum AuthScreenMode: String, CaseIterable, Identifiable {
    case signIn = "로그인"
    case signUp = "회원가입"

    var id: String { rawValue }
}

struct SignUpView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    @State private var mode: AuthScreenMode = .signIn
    @State private var email = ""
    @State private var password = ""
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
                    Picker("인증 모드", selection: $mode) {
                        ForEach(AuthScreenMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("이메일")
                            .font(.subheadline.weight(.semibold))
                        TextField("name@example.com", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("비밀번호")
                            .font(.subheadline.weight(.semibold))
                        SecureField("비밀번호", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    }

                    if mode == .signUp {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("표시 이름")
                                .font(.subheadline.weight(.semibold))
                            TextField("표시 이름(선택)", text: $displayName)
                                .padding(14)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                        }
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
                                Text(mode == .signIn ? "로그인" : "회원가입")
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
        .onChange(of: email) { _, _ in
            errorMessage = nil
        }
        .onChange(of: password) { _, _ in
            errorMessage = nil
        }
        .onChange(of: mode) { _, _ in
            errorMessage = nil
        }
    }

    private func signUp() {
        errorMessage = nil
        isSubmitting = true

        Task {
            defer {
                isSubmitting = false
            }

            do {
                if mode == .signIn {
                    try await sessionStore.signIn(email: email, password: password)
                } else {
                    try await sessionStore.signUp(
                        email: email,
                        password: password,
                        displayName: displayName
                    )
                }
            } catch let error as AuthError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = AuthError.unknown.errorDescription
            }
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(SessionStore())
}
