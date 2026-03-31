import Foundation

// MARK: - Authentication Errors

internal enum AuthError: LocalizedError, Sendable {
    case signInCancelled
    case signInFailed(String)
    case signOutFailed(String)
    case tokenStorageFailed
    case networkUnavailable
    case missingCredential

    internal var errorDescription: String? {
        switch self {
        case .signInCancelled:
            String(localized: "Đăng nhập đã bị huỷ.")
        case .signInFailed(let reason):
            String(localized: "Đăng nhập thất bại: \(reason)")
        case .signOutFailed(let reason):
            String(localized: "Đăng xuất thất bại: \(reason)")
        case .tokenStorageFailed:
            String(localized: "Không thể lưu thông tin xác thực.")
        case .networkUnavailable:
            String(localized: "Lỗi kết nối. Vui lòng kiểm tra mạng và thử lại.")
        case .missingCredential:
            String(localized: "Không nhận được thông tin xác thực.")
        }
    }
}
