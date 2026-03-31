# Export (Xuất dữ liệu)

Xuất giao dịch ra file CSV hoặc PDF với bộ lọc theo khoảng thời gian và loại giao dịch.

## Files

| File | Purpose |
|------|---------|
| `ExportView.swift` | Form xuất dữ liệu: chọn khoảng thời gian, định dạng (CSV/PDF), lọc loại, xem trước số lượng, nút xuất. Bao gồm ShareSheet (UIKit wrapper) |
| `ExportViewModel.swift` | ViewModel xử lý lọc giao dịch, gọi ExportService tạo file CSV/PDF, ghi file tạm |

## Data Dependencies

- `Transaction` — nguồn dữ liệu xuất, lọc theo ngày và loại
- `ExportService` — service tạo nội dung CSV và PDF
- `TransactionDTO` — chuyển đổi Transaction sang DTO cho export
- `ExportFormat` — enum định dạng file (CSV, PDF)

## Navigation

- Routes handled: không xử lý route riêng
- Truy cập từ: SettingsView (NavigationLink)
- Presents: ShareSheet (UIActivityViewController) để chia sẻ file đã xuất
