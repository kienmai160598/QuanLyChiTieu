import SwiftUI
import SwiftData

// MARK: - SettingsView

internal struct SettingsView: View {
    @Environment(\.modelContext) internal var context
    @Environment(LanguageManager.self) internal var languageManager
    @Environment(AuthService.self) internal var authService
    @AppStorage("isDarkMode") internal var isDarkMode = false
    @State internal var viewModel = SettingsViewModel()
    @State internal var isShowingAuthSheet = false
    @State internal var showLanguageRestartAlert = false

    internal var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                profileSection
                featuresSection
                preferencesSection
                securitySection
                dataSection
                accountSection
                authorCard
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.appSurface.ignoresSafeArea())
        .navigationTitle(String(localized: "Cài đặt"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.loadUserName(context: context)
            await viewModel.loadBiometricState()
            await viewModel.checkNotificationStatus()
        }
        .sheet(isPresented: $isShowingAuthSheet) {
            AuthView(authService: authService)
        }
        .confirmationDialog(
            String(localized: "Đăng xuất?"),
            isPresented: $viewModel.isAwaitingSignOutConfirmation,
            titleVisibility: .visible
        ) { signOutDialogButtons }
            message: { signOutDialogMessage }
        .alert(
            String(localized: "Xoá dữ liệu?"),
            isPresented: $viewModel.isAwaitingResetConfirmation
        ) { resetAlertButtons }
            message: { resetAlertMessage }
        .alert(
            String(localized: "Lỗi"),
            isPresented: errorBinding(for: \.signOutError)
        ) { Button(String(localized: "OK")) {} }
            message: { Text(viewModel.signOutError ?? "") }
        .alert(
            String(localized: "Lỗi xác thực"),
            isPresented: errorBinding(for: \.biometricAuthError)
        ) { Button(String(localized: "OK")) {} }
            message: { Text(viewModel.biometricAuthError ?? "") }
        .alert(
            String(localized: "Lỗi"),
            isPresented: errorBinding(for: \.errorMessage)
        ) { Button(String(localized: "OK")) {} }
            message: { Text(viewModel.errorMessage ?? "") }
        .alert(
            String(localized: "Khởi động lại"),
            isPresented: $showLanguageRestartAlert
        ) { Button(String(localized: "OK")) {} }
            message: {
            Text(String(localized: "Vui lòng khởi động lại ứng dụng để áp dụng ngôn ngữ mới"))
        }
    }
}

// MARK: - Sections

private extension SettingsView {
    var profileSection: some View {
        NavigationLink(value: DashboardRoute.profileSetup) {
            HStack(spacing: Spacing.lg) {
                profileAvatar(size: 56, fontSize: 22)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(displayName)
                        .font(Typography.titleMedium)
                        .foregroundStyle(Color.onSurface)
                    Text(emailOrGuest)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            .padding(Spacing.lg)
        }
        .buttonStyle(.plain)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge)
    }

    var featuresSection: some View {
        settingsCard(title: "Tính năng") {
            budgetRow
            Divider()
            debtRow
            Divider()
            eventRow
            Divider()
            insightsRow
        }
    }

    var preferencesSection: some View {
        settingsCard(title: "Tuỳ chọn") {
            languageRow
            Divider()
            darkModeRow
            Divider()
            notificationRow
            Divider()
            backTapRow
        }
    }

    var securitySection: some View {
        settingsCard(title: "Bảo mật") {
            biometricRow
            if viewModel.faceIDEnabled {
                Divider()
                lockTimeoutRow
            }
        }
    }

    var dataSection: some View {
        settingsCard(title: "Dữ liệu") {
            categoryRow
            Divider()
            exportRow
            Divider()
            recurringRow
        }
    }

    var accountSection: some View {
        settingsCard(title: "Tài khoản") {
            accountActionRow
            Divider()
            deleteRow
        }
    }
}

// MARK: - Glass Card Builder

private extension SettingsView {
    func settingsCard<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .padding(.leading, Spacing.sm)

            VStack(spacing: 0) {
                content()
            }
            .padding(.vertical, Spacing.xs)
            .m3Card(cornerRadius: Spacing.cornerExtraLarge)
        }
    }
}

// MARK: - Alerts & Dialogs

private extension SettingsView {
    func errorBinding(
        for keyPath: ReferenceWritableKeyPath<SettingsViewModel, String?>
    ) -> Binding<Bool> {
        Binding(
            get: { viewModel[keyPath: keyPath] != nil },
            set: { if !$0 { viewModel[keyPath: keyPath] = nil } }
        )
    }

    @ViewBuilder
    var signOutDialogButtons: some View {
        Button(String(localized: "Đăng xuất và xoá dữ liệu"), role: .destructive) {
            Task {
                do { try await authService.signOutAndClearData(context: context) }
                catch { viewModel.signOutError = error.localizedDescription }
            }
        }
        Button(String(localized: "Chỉ đăng xuất")) {
            Task {
                do { try await authService.signOut() }
                catch { viewModel.signOutError = error.localizedDescription }
            }
        }
        Button(String(localized: "Huỷ"), role: .cancel) {}
    }

    var signOutDialogMessage: some View {
        Text(String(localized: "Xoá dữ liệu sẽ xoá toàn bộ giao dịch, danh mục và ngân sách trên thiết bị này."))
    }

    @ViewBuilder
    var resetAlertButtons: some View {
        Button(String(localized: "Huỷ"), role: .cancel) {}
        Button(String(localized: "Xoá"), role: .destructive) {
            Task { await viewModel.resetAllData(context: context) }
        }
    }

    var resetAlertMessage: some View {
        Text(String(localized: "Tất cả giao dịch, danh mục và ngân sách sẽ bị xoá. Không thể hoàn tác."))
    }
}

// MARK: - Helpers

private extension SettingsView {
    var emailOrGuest: String {
        if authService.isSignedIn, let email = authService.currentUserEmail {
            return email
        }
        return String(localized: "Khách")
    }

    var displayName: String {
        authService.currentUserName ?? viewModel.userName
    }

    var avatarInitial: String {
        guard let char = displayName.trimmingCharacters(
            in: .whitespaces
        ).first else { return "?" }
        return String(char).uppercased()
    }

    func profileAvatar(size: CGFloat, fontSize: CGFloat) -> some View {
        Group {
            if let photoURL = authService.currentUserPhotoURL {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initialAvatar(size: size, fontSize: fontSize)
                    }
                }
            } else {
                initialAvatar(size: size, fontSize: fontSize)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    func initialAvatar(size: CGFloat, fontSize: CGFloat) -> some View {
        Circle()
            .fill(Color.appPrimary)
            .frame(width: size, height: size)
            .overlay {
                Text(avatarInitial)
                    .font(Typography.headlineSmall)
                    .foregroundStyle(Color.onPrimary)
            }
    }
}
