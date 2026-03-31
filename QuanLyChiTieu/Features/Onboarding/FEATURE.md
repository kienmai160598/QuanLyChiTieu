# Onboarding (Giới thiệu)

Luồng giới thiệu ứng dụng 4 trang: chào mừng, ngân sách, báo cáo, bắt đầu. Hiển thị khi lần đầu mở app.

## Files

| File | Purpose |
|------|---------|
| `OnboardingView.swift` | Container TabView paged chứa 4 trang onboarding |
| `OnboardingViewModel.swift` | ViewModel quản lý trang hiện tại, advance/skip, lưu flag hoàn thành vào UserDefaults |
| `Pages/WelcomePage.swift` | Trang chào mừng: hero cards cascade, giới thiệu quản lý chi tiêu |
| `Pages/BudgetPage.swift` | Trang ngân sách: semicircular gauge, budget bars, giới thiệu lập ngân sách |
| `Pages/InsightsPage.swift` | Trang báo cáo: card stack mockup biểu đồ, giới thiệu phân tích chi tiết |
| `Pages/InsightsPageShapes.swift` | Custom Shape: SparklineShape, AreaChartShape, AreaChartLine, PulseLine |
| `Pages/GetStartedPage.swift` | Trang cuối: orbiting feature chips, nút "Bắt đầu ngay" hoàn thành onboarding |

## Data Dependencies

- `UserDefaults` ("hasCompletedOnboarding") — flag kiểm soát hiển thị onboarding

## Navigation

- Routes handled: không xử lý route riêng
- Hiển thị conditional tại root app dựa trên `hasCompletedOnboarding`
- GetStartedPage gọi `completeOnboarding()` để chuyển sang main app
