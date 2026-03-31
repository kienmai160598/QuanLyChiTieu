# AddTransaction (Thêm giao dịch)

Form thêm giao dịch mới với giao diện custom (không dùng Form): chọn loại, nhập số tiền, chọn danh mục, ghi chú, chọn ngày.

## Files

| File | Purpose |
|------|---------|
| `AddTransactionView.swift` | Composition root: form layout, note, date picker, save button, overlay |
| `AddTransactionTypeToggle.swift` | Type toggle buttons (chi tiêu/thu nhập) + amount input card |
| `AddTransactionCategoryGrid.swift` | Category grid with selection highlight |
| `AddTransactionViewModel.swift` | ViewModel xử lý state form, validation, lưu giao dịch vào SwiftData, reset form |

## Data Dependencies

- `Transaction` — tạo và insert giao dịch mới
- `Category` — hiển thị grid danh mục, lọc theo loại (expense/income)

## Navigation

- Routes handled: không xử lý route riêng
- Hiển thị dạng sheet từ DashboardView
