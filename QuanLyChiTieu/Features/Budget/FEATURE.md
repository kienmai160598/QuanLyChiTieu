# Budget (Ngân sách)

Quản lý ngân sách theo danh mục: tổng quan tiến độ, danh sách ngân sách từng danh mục, thêm ngân sách mới.

## Files

| File | Purpose |
|------|---------|
| `BudgetListView.swift` | Màn hình danh sách ngân sách: circular progress tổng, danh sách card từng danh mục với progress bar |
| `BudgetListViewModel.swift` | ViewModel tính toán tổng chi/ngân sách, chi tiêu theo danh mục, CRUD ngân sách |
| `AddBudgetSheet.swift` | Sheet thêm ngân sách: nhập hạn mức, chọn danh mục expense, validate trùng lặp |

## Data Dependencies

- `Budget` — CRUD ngân sách, lọc theo monthYear hiện tại
- `Transaction` — tính tổng chi tiêu theo danh mục trong tháng
- `Category` — hiển thị danh sách danh mục expense để chọn

## Navigation

- Routes handled: `BudgetRoute.detail`, `BudgetRoute.addBudget`
- Presents: `AddBudgetSheet` (sheet)
