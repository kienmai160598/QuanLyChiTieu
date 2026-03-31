// MARK: - Purpose: Unified app-level error type for keychain, biometric, data, and export failures
import Foundation

// MARK: - Domain Error Types

internal enum AppError: LocalizedError, Sendable {
    case keychainReadFailed(String)
    case keychainWriteFailed(String)
    case keychainDeleteFailed(String)
    case biometricNotAvailable
    case biometricFailed
    case biometricLockout
    case biometricCancelled
    case dataCorrupted
    case exportFailed(String)
    case fileProtectionFailed

    internal var errorDescription: String? {
        switch self {
        case .keychainReadFailed(let key):
            String(localized: "Không thể đọc dữ liệu bảo mật cho \(key).")
        case .keychainWriteFailed(let key):
            String(localized: "Không thể lưu dữ liệu bảo mật cho \(key).")
        case .keychainDeleteFailed(let key):
            String(localized: "Không thể xoá dữ liệu bảo mật cho \(key).")
        case .biometricNotAvailable:
            String(localized: "Xác thực sinh trắc học không khả dụng trên thiết bị này.")
        case .biometricFailed:
            String(localized: "Xác thực sinh trắc học thất bại.")
        case .biometricLockout:
            String(localized: "Xác thực sinh trắc học đã bị khoá do nhiều lần thử sai.")
        case .biometricCancelled:
            String(localized: "Xác thực đã bị huỷ bởi người dùng.")
        case .dataCorrupted:
            String(localized: "Dữ liệu ứng dụng bị hỏng.")
        case .exportFailed(let reason):
            String(localized: "Xuất dữ liệu thất bại: \(reason).")
        case .fileProtectionFailed:
            String(localized: "Không thể thiết lập bảo vệ tệp dữ liệu.")
        }
    }

    internal var recoverySuggestion: String? {
        switch self {
        case .keychainReadFailed, .keychainWriteFailed, .keychainDeleteFailed:
            String(localized: "Vui lòng thử lại. Nếu lỗi tiếp tục, hãy khởi động lại ứng dụng.")
        case .biometricNotAvailable:
            String(localized: "Vui lòng bật Face ID hoặc Touch ID trong Cài đặt thiết bị.")
        case .biometricFailed:
            String(localized: "Vui lòng thử lại hoặc sử dụng mã khoá thiết bị.")
        case .biometricLockout:
            String(localized: "Vui lòng mở khoá thiết bị bằng mã PIN trước, sau đó thử lại.")
        case .biometricCancelled:
            nil
        case .dataCorrupted:
            String(localized: "Vui lòng xoá dữ liệu ứng dụng và thiết lập lại từ đầu.")
        case .exportFailed:
            String(localized: "Vui lòng kiểm tra dung lượng bộ nhớ và thử lại.")
        case .fileProtectionFailed:
            String(localized: "Vui lòng khởi động lại ứng dụng.")
        }
    }
}
