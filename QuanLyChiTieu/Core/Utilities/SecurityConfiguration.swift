// MARK: - Purpose: Security constants, file protection, and ATS validation configuration
import Foundation
import UIKit
import UniformTypeIdentifiers

// MARK: - Secure Storable Protocol

internal protocol SecureStorable: Sendable {
    var secureKey: String { get }
    func toData() throws -> Data
    static func fromData(_ data: Data) throws -> Self
}

// MARK: - Security Configuration

internal enum SecurityConfiguration: Sendable {
    internal static let keychainServiceName = "com.quanlychitieu.keychain"
    internal static let keychainAccessGroup: String? = nil

    internal static let lockTimeoutInterval: TimeInterval = 300
    internal static let clipboardExpirationInterval: TimeInterval = 60

    // MARK: - Clipboard

    internal static func copyToClipboardWithExpiration(_ string: String) {
        UIPasteboard.general.setItems(
            [[UTType.plainText.identifier: string]],
            options: [.expirationDate: Date().addingTimeInterval(clipboardExpirationInterval)]
        )
    }

    // MARK: - Lock Timeout Options

    internal enum LockTimeoutOption: String, CaseIterable, Sendable {
        case immediately = "0"
        case oneMinute = "60"
        case fiveMinutes = "300"

        internal var interval: TimeInterval {
            switch self {
            case .immediately: 0
            case .oneMinute: 60
            case .fiveMinutes: 300
            }
        }

        internal var displayName: String {
            switch self {
            case .immediately: String(localized: "Ngay lập tức")
            case .oneMinute: String(localized: "Sau 1 phút")
            case .fiveMinutes: String(localized: "Sau 5 phút")
            }
        }
    }

    // MARK: - File Protection

    internal static func applyFileProtection(to url: URL) throws {
        do {
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: url.path
            )
        } catch {
            throw AppError.fileProtectionFailed
        }
    }

    internal static func applyFileProtection(
        toStoreAt directoryURL: URL
    ) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return
        }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil
            )
            for fileURL in contents where fileURL.pathExtension == "store" {
                try applyFileProtection(to: fileURL)
            }
        } catch let appError as AppError {
            throw appError
        } catch {
            throw AppError.fileProtectionFailed
        }
    }

    // MARK: - ATS Validation (Debug Only)

    #if DEBUG
    internal static func validateATSConfiguration() {
        guard let infoPlist = Bundle.main.infoDictionary else {
            return
        }
        if let ats = infoPlist["NSAppTransportSecurity"] as? [String: Any],
            let allowsArbitrary = ats["NSAllowsArbitraryLoads"] as? Bool,
            allowsArbitrary
        {
            assertionFailure(
                "ATS: NSAllowsArbitraryLoads must be false for a financial app."
            )
        }
    }
    #endif
}
