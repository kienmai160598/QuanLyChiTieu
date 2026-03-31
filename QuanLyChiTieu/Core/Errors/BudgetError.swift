// MARK: - Purpose: Domain errors for budget creation, update, and deletion operations
import Foundation

// MARK: - Budget Error

/// Domain-specific errors for budget operations.
/// User-facing messages are in Vietnamese. Technical details in associated values.
internal enum BudgetError: LocalizedError, Sendable {
    case invalidLimit
    case categoryRequired
    case duplicateBudget
    case saveFailed(String)
    case deleteFailed(String)

    // MARK: - LocalizedError

    internal var errorDescription: String? {
        switch self {
        case .invalidLimit:
            return "Hạn mức không hợp lệ"
        case .categoryRequired:
            return "Vui lòng chọn danh mục"
        case .duplicateBudget:
            return "Ngân sách đã tồn tại cho danh mục này"
        case .saveFailed:
            return "Không thể lưu ngân sách"
        case .deleteFailed:
            return "Không thể xoá ngân sách"
        }
    }

    internal var recoverySuggestion: String? {
        switch self {
        case .invalidLimit:
            return "Nhập số tiền hạn mức lớn hơn 0."
        case .categoryRequired:
            return "Chọn một danh mục trước khi tạo ngân sách."
        case .duplicateBudget:
            return "Mỗi danh mục chỉ có thể có một ngân sách mỗi tháng. Hãy chỉnh sửa ngân sách hiện tại."
        case .saveFailed(let detail):
            return "Kiểm tra bộ nhớ thiết bị và thử lại. (\(detail))"
        case .deleteFailed(let detail):
            return "Thử lại sau vài giây. (\(detail))"
        }
    }

    internal var failureReason: String? {
        switch self {
        case .invalidLimit:
            return "Budget limit must be greater than zero."
        case .categoryRequired:
            return "A category must be selected before creating a budget."
        case .duplicateBudget:
            return "A budget already exists for this category in the current month."
        case .saveFailed(let detail):
            return "SwiftData save failed: \(detail)"
        case .deleteFailed(let detail):
            return "SwiftData delete failed: \(detail)"
        }
    }
}
