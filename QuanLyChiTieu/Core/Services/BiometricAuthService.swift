// MARK: - Purpose: Face ID / Touch ID authentication with passcode fallback
import Foundation
import LocalAuthentication
import os

// MARK: - Biometric Auth Service

@MainActor @Observable
internal final class BiometricAuthService {
    internal private(set) var isAuthenticated: Bool = false
    internal private(set) var biometryType: LABiometryType = .none
    internal private(set) var isAvailable: Bool = false
    internal private(set) var lastAuthDate: Date?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "QuanLyChiTieu",
        category: "BiometricAuth"
    )

    internal init() {
        checkAvailability()
    }

    // MARK: - Public Methods

    internal func authenticate(
        reason: String = String(
            localized: "Xác thực để truy cập ứng dụng"
        )
    ) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = String(localized: "Huỷ")

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            handleAuthResult(success: success)
            return success
        } catch let error as LAError {
            return handleError(error)
        } catch {
            logger.error("Lỗi xác thực không xác định")
            isAuthenticated = false
            return false
        }
    }

    internal func checkAvailability() {
        let context = LAContext()
        var error: NSError?
        let biometricsAvailable = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
        isAvailable = biometricsAvailable
        biometryType = context.biometryType
    }

    internal func invalidateAuthentication() {
        isAuthenticated = false
        lastAuthDate = nil
    }

    internal func hasAuthenticationExpired(
        timeout: TimeInterval = SecurityConfiguration.lockTimeoutInterval
    ) -> Bool {
        guard let lastAuth = lastAuthDate else {
            return true
        }
        return Date().timeIntervalSince(lastAuth) > timeout
    }

    // MARK: - Private Helpers

    private func handleAuthResult(success: Bool) {
        isAuthenticated = success
        if success {
            lastAuthDate = Date()
        }
    }

    private func handleError(_ error: LAError) -> Bool {
        switch error.code {
        case .userCancel, .systemCancel, .appCancel:
            logger.info("Xác thực đã bị huỷ")
        default:
            logger.error("Lỗi xác thực: \(error.code.rawValue)")
        }
        isAuthenticated = false
        return false
    }
}
