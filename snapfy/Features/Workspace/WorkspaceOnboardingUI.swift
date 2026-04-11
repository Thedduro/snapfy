import SwiftUI

enum WorkspaceOnboardingPresentation {
    case fullScreen
    case popup
}

enum WorkspaceOnboardingPalette {
    static let primary = Color(red: 0.96, green: 0.58, blue: 0.48)
    static let secondary = Color(red: 0.99, green: 0.72, blue: 0.60)
    static let mintGlow = Color(red: 1.00, green: 0.88, blue: 0.82)
    static let backgroundTop = Color(red: 1.00, green: 0.98, blue: 0.97)
    static let backgroundBottom = Color(red: 0.99, green: 0.95, blue: 0.93)
    static let cardTint = Color.white.opacity(0.72)
    static let border = Color.white.opacity(0.55)
    static let fieldBorder = Color(red: 0.96, green: 0.80, blue: 0.72)
    static let fieldFocus = Color(red: 0.95, green: 0.52, blue: 0.44)
    static let subtitle = Color(red: 0.38, green: 0.30, blue: 0.30)
}

struct WorkspaceOnboardingBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    WorkspaceOnboardingPalette.backgroundTop,
                    WorkspaceOnboardingPalette.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            WorkspaceOnboardingPalette.mintGlow.opacity(0.75),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 26)
                .offset(x: -140, y: -210)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            WorkspaceOnboardingPalette.primary.opacity(0.18),
                            WorkspaceOnboardingPalette.secondary.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: 30)
                .offset(x: 160, y: -100)
        }
        .ignoresSafeArea()
    }
}

struct WorkspaceSurfaceCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            content
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(WorkspaceOnboardingPalette.cardTint)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(WorkspaceOnboardingPalette.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
    }
}

struct WorkspaceFieldShell<Content: View>: View {
    let title: String
    let hint: String
    let icon: String
    let isFocused: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WorkspaceOnboardingPalette.primary)
                    .frame(width: 18)

                content
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isFocused ? WorkspaceOnboardingPalette.fieldFocus : WorkspaceOnboardingPalette.fieldBorder.opacity(0.6),
                        lineWidth: isFocused ? 1.8 : 1
                    )
            )
            .shadow(
                color: isFocused ? WorkspaceOnboardingPalette.fieldFocus.opacity(0.24) : .clear,
                radius: 14,
                y: 0
            )

            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
        }
    }
}

struct WorkspacePrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .tracking(0.2)
                }
                Spacer()
            }
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(
            LinearGradient(
                colors: [
                    WorkspaceOnboardingPalette.primary,
                    WorkspaceOnboardingPalette.secondary
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: Capsule(style: .continuous)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
        )
        .shadow(color: WorkspaceOnboardingPalette.primary.opacity(0.35), radius: 14, y: 10)
        .opacity(isDisabled ? 0.6 : 1)
        .disabled(isDisabled)
    }
}

struct WorkspaceCenteredPopup<Content: View>: View {
    let onClose: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            content
                .frame(maxWidth: 380)
                .padding(.horizontal, 14)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}
