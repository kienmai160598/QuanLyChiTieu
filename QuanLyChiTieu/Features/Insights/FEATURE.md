# Insights (Báo cáo)

Báo cáo chi tiêu trực quan với biểu đồ: chi tiêu theo danh mục, xu hướng hàng tháng, thu nhập vs chi tiêu, tiến độ ngân sách.

## Files

| File | Purpose |
|------|---------|
| `InsightsView.swift` | View chính: period picker (tuần/tháng/năm), tổ hợp 4 biểu đồ |
| `InsightsViewModel.swift` | ViewModel xử lý lọc theo khoảng thời gian, tính toán dữ liệu cho từng biểu đồ |
| `InsightsChartData.swift` | Kiểu dữ liệu: TimePeriod, CategoryBreakdownItem, MonthlyTrendItem, IncomeExpenseItem |
| `Components/SpendingByCategoryChart.swift` | Biểu đồ tròn chi tiêu theo danh mục với legend tương tác |
| `Components/MonthlyTrendChart.swift` | Biểu đồ đường xu hướng chi tiêu hàng tháng |
| `Components/IncomeExpenseChart.swift` | Biểu đồ cột so sánh thu nhập và chi tiêu theo tháng |
| `Components/BudgetUtilizationCard.swift` | Card hiển thị tiến độ sử dụng ngân sách với circular progress |

## Data Dependencies

- `Transaction` — nguồn dữ liệu chính cho tất cả biểu đồ, lọc theo khoảng thời gian
- `Budget` — hiển thị tiến độ ngân sách trong section cuối
- `Category` — icon, màu, tên danh mục cho biểu đồ

## Navigation

- Routes handled: không xử lý route riêng
- Truy cập từ: DashboardView (NavigationLink và category breakdown card)
