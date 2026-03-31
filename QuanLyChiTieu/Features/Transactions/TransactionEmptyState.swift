import SwiftUI

// MARK: - Glass Empty State (No Transactions)

internal struct TransactionEmptyState: View {
    internal var onAdd: (() -> Void)?

    internal var body: some View {
        if let onAdd {
            EmptyStateCard(
                icon: "tray",
                title: String(localized: "Chưa có giao dịch nào"),
                subtitle: String(localized: "Hãy thêm giao dịch đầu tiên để bắt đầu theo dõi chi tiêu"),
                actionLabel: String(localized: "Thêm giao dịch"),
                onAction: onAdd
            )
        } else {
            EmptyStateCard(
                icon: "tray",
                title: String(localized: "Chưa có giao dịch nào"),
                subtitle: String(localized: "Hãy thêm giao dịch đầu tiên để bắt đầu theo dõi chi tiêu")
            )
        }
    }
}

// MARK: - Glass Empty State (Filter)

internal struct TransactionFilterEmptyState: View {
    internal var body: some View {
        EmptyStateCard(
            icon: "magnifyingglass",
            title: String(localized: "Không tìm thấy"),
            subtitle: String(localized: "Thử thay đổi bộ lọc hoặc từ khoá tìm kiếm")
        )
    }
}
