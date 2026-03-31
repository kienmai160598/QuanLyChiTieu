# Transactions (Giao dịch)

Quản lý danh sách giao dịch: xem, tìm kiếm, lọc, xem chi tiết, sửa, xoá. Bao gồm cả quản lý giao dịch định kỳ.

## Files

| File | Purpose |
|------|---------|
| `TransactionListView.swift` | Composition root: danh sách giao dịch với search, nhóm theo ngày, xoá |
| `TransactionFilterChips.swift` | Filter chip row: lọc theo tất cả/chi tiêu/thu nhập |
| `TransactionRowView.swift` | Reusable transaction row: icon, title, amount, context menu |
| `TransactionDetailView.swift` | Màn hình chi tiết giao dịch: số tiền, danh mục, ngày, ghi chú, nút sửa/xoá |
| `TransactionDetailViewModel.swift` | ViewModel cho chi tiết giao dịch: format dữ liệu, xoá giao dịch |
| `EditTransactionView.swift` | Form sửa giao dịch: loại, số tiền, danh mục, ghi chú, ngày |
| `EditTransactionViewModel.swift` | ViewModel cho sửa giao dịch: validation, detect changes, save |
| `RecurringTransactionView.swift` | Danh sách giao dịch định kỳ: active/inactive, toggle on/off, xoá |
| `AddRecurringView.swift` | Form thêm giao dịch định kỳ: loại, số tiền, danh mục, tần suất, ngày bắt đầu/kết thúc |

## Data Dependencies

- `Transaction` — CRUD giao dịch, lọc theo loại và search text
- `Category` — hiển thị và chọn danh mục cho giao dịch
- `RecurringTransaction` — CRUD giao dịch định kỳ, toggle active/inactive

## Navigation

- Routes handled: `TransactionRoute.detail`, `TransactionRoute.edit`
- Presents: `EditTransactionView` (sheet từ detail), `AddRecurringView` (sheet từ recurring list)
