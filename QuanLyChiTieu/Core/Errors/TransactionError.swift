// MARK: - Purpose: Domain errors for transaction CRUD and fetch operations
import Foundation

// MARK: - Transaction Error

/// Domain-specific errors for transaction operations.
/// User-facing messages are in Vietnamese. Technical details in associated values.
internal enum TransactionError: LocalizedError, Sendable {
    case invalidAmount
    case categoryRequired
    case saveFailed(String)
    case deleteFailed(String)
    case fetchFailed(String)
    case invalidDateRange

    // MARK: - LocalizedError

    internal var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Số tiền không hợp lệ"
        case .categoryRequired:
            return "Vui lòng chọn danh mục"
        case .saveFailed:
            return "Không thể lưu giao dịch"
        case .deleteFailed:
            return "Không thể xoá giao dịch"
        case .fetchFailed:
            return "Không thể tải danh sách giao dịch"
        case .invalidDateRange:
            return "Ngày kết thúc phải sau ngày bắt đầu"
        }
    }

    internal var recoverySuggestion: String? {
        switch self {
        case .invalidAmount:
            return "Nhập số tiền lớn hơn 0."
        case .categoryRequired:
            return "Chọn một danh mục trước khi lưu."
        case .saveFailed(let detail):
            return "Kiểm tra bộ nhớ thiết bị và thử lại. (\(detail))"
        case .deleteFailed(let detail):
            return "Thử lại sau vài giây. (\(detail))"
        case .fetchFailed(let detail):
            return "Khởi động lại ứng dụng nếu lỗi tiếp tục. (\(detail))"
        case .invalidDateRange:
            return "Chọn ngày kết thúc sau ngày bắt đầu."
        }
    }

    internal var failureReason: String? {
        switch self {
        case .invalidAmount:
            return "Amount must be greater than zero."
        case .categoryRequired:
            return "A category must be selected before saving."
        case .saveFailed(let detail):
            return "SwiftData save failed: \(detail)"
        case .deleteFailed(let detail):
            return "SwiftData delete failed: \(detail)"
        case .fetchFailed(let detail):
            return "SwiftData fetch failed: \(detail)"
        case .invalidDateRange:
            return "End date must be after start date."
        }
    }
}
