# Dashboard (Tổng quan)

Màn hình chính hiển thị tổng quan tài chính tháng hiện tại: số dư, tiến độ chi tiêu, ngân sách, giao dịch gần đây và giao dịch định kỳ sắp tới.

## Files

| File | Purpose |
|------|---------|
| `DashboardView.swift` | View chính, tổ hợp các section: greeting, month selector, balance hero, spending chart, quick actions, summary, budget, recent, recurring |
| `DashboardViewModel.swift` | ViewModel xử lý logic tính toán số dư, chi tiêu, ngân sách, giao dịch định kỳ sắp tới |
| `DashboardViewModelBuilders.swift` | Extension methods cho ViewModel: build pill arc slices, mid angles, score data |
| `DashboardGreetingHeader.swift` | Header chào hỏi người dùng theo thời gian trong ngày, kèm avatar và nút cài đặt |
| `DashboardMonthSelector.swift` | Bộ chọn tháng dạng horizontal scroll |
| `DashboardBalanceHero.swift` | Hero card hiển thị số dư, thu/chi tháng với M3 Expressive styling |
| `DashboardSpendingChart.swift` | Biểu đồ chi tiêu dạng PillArcChart với popup chi tiết danh mục |
| `DashboardQuickActions.swift` | Hàng nút hành động nhanh (thêm giao dịch, v.v.) |
| `DashboardSummaryCards.swift` | Cards tóm tắt tài chính: thu, chi, tiết kiệm |
| `DashboardScoreCards.swift` | Cards điểm số sức khỏe tài chính |
| `DashboardCategoryChips.swift` | Chip lọc theo danh mục chi tiêu |
| `DashboardBudgetSection.swift` | Section ngân sách với progress bar từng danh mục và link đến BudgetListView |
| `DashboardRecentSection.swift` | Section giao dịch gần đây |
| `DashboardUpcomingRecurring.swift` | Section giao dịch định kỳ sắp tới với link đến RecurringTransactionView |
| `DashboardAnimations.swift` | Entrance animation modifiers: sectionEntrance, staggeredEntrance |
| `DashboardTypes.swift` | Kiểu dữ liệu hỗ trợ: CategorySpend, BudgetSummary, UpcomingRecurring, PieSlice |
| `ProfileSetupView.swift` | Màn hình thiết lập hồ sơ người dùng |
| `ProfileSetupComponents.swift` | Components dùng trong ProfileSetupView |
| `ProfileSetupViewModel.swift` | ViewModel cho ProfileSetupView |
| `UpcomingRecurringBuilder.swift` | Logic tính toán giao dịch định kỳ sắp tới |

### Deleted Files

| File | Reason |
|------|--------|
| `DashboardPillsCard.swift` | Thay thế bởi DashboardSummaryCards |
| `DashboardDateStrip.swift` | Thay thế bởi DashboardMonthSelector |

## Data Dependencies

- `Transaction` — lọc giao dịch tháng hiện tại, tính thu/chi/số dư, hiển thị giao dịch gần đây
- `Budget` — tính tiến độ ngân sách theo danh mục
- `RecurringTransaction` — tính ngày đến hạn tiếp theo cho giao dịch định kỳ
- `Category` — hiển thị icon, màu, tên danh mục

## Navigation

- Routes handled: `DashboardRoute.transactionDetail`, `DashboardRoute.budgetList`, `DashboardRoute.recurringList`
- Presents: `AddTransactionView` (sheet), `InsightsView` (push), `BudgetListView` (push), `RecurringTransactionView` (push)
