import SwiftUI

enum WorkspaceOnboardingPalette {
    static let primary = Color(red: 0.24, green: 0.73, blue: 0.52)
    static let secondary = Color(red: 0.56, green: 0.87, blue: 0.74)
    static let mintGlow = Color(red: 0.78, green: 0.95, blue: 0.89)
    static let backgroundTop = Color(red: 0.97, green: 1.00, blue: 0.99)
    static let backgroundBottom = Color(red: 0.94, green: 0.98, blue: 0.96)
    static let cardTint = Color.white.opacity(0.72)
    static let border = Color.white.opacity(0.55)
    static let fieldBorder = Color(red: 0.72, green: 0.87, blue: 0.80)
    static let fieldFocus = Color(red: 0.34, green: 0.79, blue: 0.60)
    static let subtitle = Color(red: 0.28, green: 0.37, blue: 0.33)
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

struct WorkspaceHeroSection: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.semibold))
                Text(eyebrow)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(WorkspaceOnboardingPalette.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(WorkspaceOnboardingPalette.primary.opacity(0.12))
            )

            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(WorkspaceOnboardingPalette.subtitle)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
