import SwiftUI
import SwiftData
import UserNotifications
import LocalAuthentication
import OSLog

// MARK: - Settings ViewModel

@MainActor @Observable
internal final class SettingsViewModel {

    // MARK: - Dependencies

    private let keychain = KeychainService()
    private let biometricService = BiometricAuthService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "QuanLyChiTieu", category: "Security")

    // MARK: - State

    internal var notificationStatus: String = String(localized: "Chưa xác định")
    internal var faceIDEnabled: Bool = false
    internal var isBiometricAvailable: Bool = false
    internal var biometricAuthError: String?
    internal var signOutError: String?
    internal var errorMessage: String?

    internal var lockTimeoutOption: SecurityConfiguration.LockTimeoutOption = .fiveMinutes {
        didSet {
            guard oldValue != lockTimeoutOption else { return }
            Task {
                do {
                    try await keychain.saveLockTimeout(lockTimeoutOption)
                } catch {
                    logger.error("saveLockTimeout failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    // MARK: - User Profile

    internal private(set) var userName: String = String(localized: "Bạn")

    internal func loadUserName(context: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? context.fetch(descriptor).first,
           let name = profile.displayName, !name.isEmpty {
            userName = name
        } else if let fallback = UserDefaults.standard.string(forKey: "userName") {
            userName = fallback
        } else {
            userName = String(localized: "Bạn")
        }
    }

    // MARK: - Computed Properties

    internal var avatarInitial: String {
        let trimmed = userName.trimmingCharacters(in: .whitespaces)
        if let first = trimmed.first {
            return String(first).uppercased()
        }
        return "?"
    }

    internal var appVersion: String {
        let version = Bundle.main.infoDictionary?[
            "CFBundleShortVersionString"
        ] as? String
        return version ?? "1.0.0"
    }

    internal var biometricTypeName: String {
        switch biometricService.biometryType {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        default: String(localized: "Sinh trắc học")
        }
    }

    internal var biometricIcon: String {
        switch biometricService.biometryType {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        default: "lock.fill"
        }
    }

    internal var biometricStatusText: String {
        if !isBiometricAvailable {
            return String(localized: "Không khả dụng trên thiết bị này")
        }
        return faceIDEnabled
            ? String(localized: "Đã bật")
            : String(localized: "Đã tắt")
    }

    // MARK: - Seed Flag Key

    private static let hasSeededKey = "com.quanlychitieu.hasSeededData"

    // MARK: - Biometric Actions

    internal func loadBiometricState() async {
        biometricService.checkAvailability()
        isBiometricAvailable = biometricService.isAvailable
        faceIDEnabled = await keychain.isBiometricLockEnabled()
        lockTimeoutOption = await keychain.loadLockTimeout()
    }

    internal func toggleBiometric() async {
        let targetState = !faceIDEnabled
        let reason = targetState
            ? String(localized: "Xác thực để bật \(biometricTypeName)")
            : String(localized: "Xác thực để tắt \(biometricTypeName)")

        let authenticated = await biometricService.authenticate(reason: reason)

        if authenticated {
            faceIDEnabled = targetState
            do {
                try await keychain.saveBiometricLockEnabled(targetState)
            } catch {
                logger.error("saveBiometricLockEnabled failed: \(error.localizedDescription, privacy: .public)")
            }
            biometricAuthError = nil
        } else {
            biometricAuthError = String(
                localized: "Xác thực thất bại. Vui lòng thử lại."
            )
        }
    }

    // MARK: - Biometric Re-authentication

    internal var isAwaitingResetConfirmation: Bool = false
    internal var isAwaitingSignOutConfirmation: Bool = false

    internal func authenticateForReset() async {
        let reason = String(localized: "Xác thực để xoá tất cả dữ liệu")
        let authenticated = await biometricService.authenticate(reason: reason)
        if authenticated {
            isAwaitingResetConfirmation = true
        } else {
            biometricAuthError = String(
                localized: "Xác thực thất bại. Vui lòng thử lại."
            )
        }
    }

    internal func authenticateForSignOut() async {
        let reason = String(localized: "Xác thực để đăng xuất")
        let authenticated = await biometricService.authenticate(reason: reason)
        if authenticated {
            isAwaitingSignOutConfirmation = true
        } else {
            biometricAuthError = String(
                localized: "Xác thực thất bại. Vui lòng thử lại."
            )
        }
    }

    // MARK: - Data Actions

    internal func resetAllData(context: ModelContext) async {
        do {
            try context.delete(model: Transaction.self)
            try context.delete(model: Budget.self)
            try context.delete(model: RecurringTransaction.self)
            try context.delete(model: Category.self)
            try context.delete(model: SavingsGoal.self)
            try context.delete(model: Debt.self)
            try context.delete(model: Event.self)
            try context.save()
            UserDefaults.standard.removeObject(forKey: Self.hasSeededKey)
        } catch {
            errorMessage = error.localizedDescription
            logger.error("resetAllData failed: \(error.localizedDescription, privacy: .public)")
            return
        }

        do {
            try await keychain.delete(for: "firebase_id_token")
            try await keychain.delete(for: "firebase_user_uid")
            try await keychain.delete(for: "isBiometricLockEnabled")
            try await keychain.delete(for: "lockTimeoutOption")
        } catch {
            logger.error("Keychain cleanup failed during reset: \(error.localizedDescription, privacy: .public)")
        }

        faceIDEnabled = false
        lockTimeoutOption = .fiveMinutes
    }

    internal func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current()
            .notificationSettings()
        switch settings.authorizationStatus {
        case .authorized:
            notificationStatus = String(localized: "Đã bật")
        case .denied:
            notificationStatus = String(localized: "Đã tắt")
        case .notDetermined:
            notificationStatus = String(localized: "Chưa cấp quyền")
        default:
            notificationStatus = String(localized: "Chưa xác định")
        }
    }

    internal var notificationsEnabled: Bool {
        notificationStatus == String(localized: "Đã bật")
    }

    internal private(set) var shouldOpenSettings: Bool = false

    internal func clearShouldOpenSettings() {
        shouldOpenSettings = false
    }

    internal func toggleNotifications() async {
        let settings = await UNUserNotificationCenter.current()
            .notificationSettings()

        if settings.authorizationStatus == .denied {
            shouldOpenSettings = true
            return
        }

        if notificationsEnabled {
            notificationStatus = String(localized: "Đã tắt")
        } else {
            await requestNotificationPermission()
        }
    }

    internal func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            notificationStatus = granted
                ? String(localized: "Đã bật")
                : String(localized: "Đã tắt")
        } catch {
            notificationStatus = String(localized: "Lỗi")
        }
    }
}
