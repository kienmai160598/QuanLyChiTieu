import SwiftUI
import AuthenticationServices

// MARK: - Auth View

internal struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: AuthViewModel

    internal init(authService: AuthService) {
        _viewModel = State(
            initialValue: AuthViewModel(authService: authService)
        )
    }

    internal var body: some View {
        ZStack {
            backgroundView
            contentView
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .alert(
            String(localized: "Lỗi đăng nhập"),
            isPresented: $viewModel.isShowingError
        ) {
            Button(String(localized: "Đồng ý")) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Layout

private extension AuthView {
    var backgroundView: some View {
        LinearGradient(
            colors: [.gradientStart.opacity(0.3), .appSurface],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    var contentView: some View {
        VStack(spacing: Spacing.xxxl) {
            dismissButton
            Spacer()
            brandingSection
            benefitsSection
            signInButtons
            Spacer()
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }

    var dismissButton: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(Typography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            .accessibilityLabel(String(localized: "Đóng"))
            Spacer()
        }
        .padding(.top, Spacing.md)
    }

    var benefitsSection: some View {
        VStack(spacing: Spacing.sm) {
            benefitRow(icon: "arrow.triangle.2.circlepath", text: String(localized: "Đồng bộ dữ liệu giữa các thiết bị"))
            benefitRow(icon: "icloud.fill", text: String(localized: "Sao lưu tự động lên iCloud"))
            benefitRow(icon: "lock.shield.fill", text: String(localized: "Bảo mật dữ liệu tài chính"))
        }
        .padding(.horizontal, Spacing.md)
    }

    func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.appSecondary)
                .frame(width: 24)
            Text(text)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            Spacer()
        }
    }
}

// MARK: - Branding

private extension AuthView {
    var brandingSection: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "wallet.bifold.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.appSecondary)

            VStack(spacing: Spacing.sm) {
                Text(String(localized: "Quản Lý Chi Tiêu"))
                    .font(Typography.heroMedium)
                    .foregroundStyle(Color.onSurface)

                Text(String(localized: "Đăng nhập để bắt đầu"))
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
    }
}

// MARK: - Sign-In Buttons

private extension AuthView {
    var signInButtons: some View {
        VStack(spacing: Spacing.lg) {
            appleSignInButton
            googleSignInButton
        }
        .padding(.horizontal, Spacing.md)
    }

    var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            viewModel.configureAppleRequest(request)
        } onCompletion: { result in
            Task {
                await viewModel.handleAppleSignIn(
                    result, context: modelContext
                )
            }
        }
        .signInWithAppleButtonStyle(
            colorScheme == .dark ? .white : .black
        )
        .frame(height: 54)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerLarge))
        .accessibilityLabel(
            String(localized: "Đăng nhập với Apple")
        )
    }

    var googleSignInButton: some View {
        Button {
            Task {
                await viewModel.handleGoogleSignIn(
                    context: modelContext
                )
            }
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "globe.americas.fill")
                    .font(Typography.titleMedium)
                    .foregroundStyle(Color.appSecondary)
                Text(String(localized: "Đăng nhập với Google"))
                    .font(Typography.labelLarge)
                    .foregroundStyle(Color.onSurface)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.plain)
        .background(Color.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerLarge))
        .overlay {
            RoundedRectangle(cornerRadius: Spacing.cornerLarge)
                .stroke(Color.outlineVariant, lineWidth: 1)
        }
        .accessibilityLabel(
            String(localized: "Đăng nhập với Google")
        )
    }
}

// MARK: - Loading

private extension AuthView {
    var loadingOverlay: some View {
        Color.primary.opacity(0.15)
            .ignoresSafeArea()
            .overlay {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color.onSurface)
            }
            .transition(.opacity)
    }
}
