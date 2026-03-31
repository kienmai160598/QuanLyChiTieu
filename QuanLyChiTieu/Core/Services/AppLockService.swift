// MARK: - Purpose: Manages app lock/unlock state with biometric authentication and timeout
import Foundation
import os
import SwiftUI

// MARK: - App Lock Service

@MainActor @Observable
internal final class AppLockService {
    internal private(set) var isLocked: Bool = true
    internal private(set) var isAuthenticating: Bool = false
    internal private(set) var lockId: Int = 0
    internal var lockTimeout: TimeInterval = SecurityConfiguration.lockTimeoutInterval

    private var backgroundDate: Date?
    private let biometricService: BiometricAuthService
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "QuanLyChiTieu",
        category: "AppLock"
    )

    internal init(biometricService: BiometricAuthService) {
        self.biometricService = biometricService
    }

    // MARK: - Unlock

    internal func unlockApp() async -> Bool {
        guard !isAuthenticating else { return false }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let success = await biometricService.authenticate()
        if success {
            isLocked = false
            backgroundDate = nil
            logger.debug("Unlocked via biometric")
        }
        return success
    }

    // MARK: - Scene Phase

    internal func handleScenePhaseChange(to phase: ScenePhase) {
        guard !isAuthenticating else { return }

        switch phase {
        case .active:
            handleBecameActive()
        case .background:
            handleEnteredBackground()
        case .inactive:
            // Ignore — triggered by system alerts, Face ID prompt, app switcher peek
            break
        @unknown default:
            break
        }
    }

    // MARK: - Private

    private func handleBecameActive() {
        guard !isLocked else { return }
        guard let bgDate = backgroundDate else { return }

        let elapsed = Date().timeIntervalSince(bgDate)
        if elapsed >= lockTimeout {
            lock()
        }
        backgroundDate = nil
    }

    private func handleEnteredBackground() {
        guard !isLocked else { return }

        if lockTimeout == 0 {
            lock()
        } else {
            backgroundDate = Date()
        }
    }

    private func lock() {
        isLocked = true
        lockId += 1
        backgroundDate = nil
        logger.debug("Locked (id: \(self.lockId))")
    }
}
