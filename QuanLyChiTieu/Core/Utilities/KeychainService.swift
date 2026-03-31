// MARK: - Purpose: Secure key-value storage using iOS Keychain Services
import Foundation
import Security

// MARK: - Keychain Error

internal enum KeychainError: LocalizedError, Sendable {
    case dataConversionFailed
    case duplicateItem
    case itemNotFound
    case unexpectedStatus(OSStatus)

    internal var errorDescription: String? {
        switch self {
        case .dataConversionFailed:
            String(localized: "Không thể chuyển đổi dữ liệu Keychain.")
        case .duplicateItem:
            String(localized: "Mục đã tồn tại trong Keychain.")
        case .itemNotFound:
            String(localized: "Không tìm thấy mục trong Keychain.")
        case .unexpectedStatus(let status):
            String(
                localized: "Lỗi Keychain không mong đợi: \(status)."
            )
        }
    }
}

// MARK: - Keychain Service

internal actor KeychainService: Sendable {
    private let serviceName: String

    internal init(serviceName: String = SecurityConfiguration.keychainServiceName) {
        self.serviceName = serviceName
    }

    internal func save(_ data: Data, for key: String) throws {
        let query = buildQuery(for: key)

        let existingStatus = SecItemCopyMatching(query as CFDictionary, nil)

        if existingStatus == errSecSuccess {
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(
                query as CFDictionary,
                updateAttributes as CFDictionary
            )
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        } else {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        }
    }

    internal func read(for key: String) throws -> Data? {
        var query = buildQuery(for: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.dataConversionFailed
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    internal func delete(for key: String) throws {
        let query = buildQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    internal func saveString(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        try save(data, for: key)
    }

    internal func readString(for key: String) throws -> String? {
        guard let data = try read(for: key) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        return string
    }

    // MARK: - Biometric Lock

    internal func saveBiometricLockEnabled(_ enabled: Bool) throws {
        try saveString(enabled ? "true" : "false", for: "isBiometricLockEnabled")
    }

    internal func isBiometricLockEnabled() -> Bool {
        let value = try? readString(for: "isBiometricLockEnabled")
        return value == "true"
    }

    // MARK: - Lock Timeout

    internal func saveLockTimeout(
        _ option: SecurityConfiguration.LockTimeoutOption
    ) throws {
        try saveString(option.rawValue, for: "lockTimeoutOption")
    }

    internal func loadLockTimeout()
        -> SecurityConfiguration.LockTimeoutOption
    {
        guard let raw = try? readString(for: "lockTimeoutOption"),
            let option = SecurityConfiguration.LockTimeoutOption(
                rawValue: raw
            )
        else {
            return .fiveMinutes
        }
        return option
    }

    // MARK: - Private Helpers

    private func buildQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String:
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
    }
}
