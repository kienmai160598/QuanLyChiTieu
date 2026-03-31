# Settings (Cài đặt)

Màn hình cài đặt: profile, giao diện (dark mode), tính năng (xuất dữ liệu, giao dịch định kỳ), thông báo, dữ liệu (xoá/reset), thông tin app.

## Files

| File | Purpose |
|------|---------|
| `SettingsView.swift` | Composition root: scroll view với các section cards |
| `SettingsCardComponents.swift` | Reusable components: SettingsCardContainer, SettingsRow, SettingsSectionHeader, SettingsCardDivider |
| `SettingsSectionViews.swift` | Section views: ProfileCard, AppearanceCard, FeaturesCard, NotificationCard, DataCard, InfoCard |
| `SettingsViewModel.swift` | ViewModel xử lý: xoá toàn bộ dữ liệu, reset onboarding, kiểm tra/yêu cầu quyền thông báo |

## Data Dependencies

- `Transaction` — xoá toàn bộ khi reset data
- `Budget` — xoá toàn bộ khi reset data
- `RecurringTransaction` — xoá toàn bộ khi reset data
- `Category` — xoá toàn bộ khi reset data (và clear seed flag để re-seed)
- `UserDefaults` ("hasCompletedOnboarding", "isDarkMode") — lưu trạng thái giao diện và onboarding
- `UNUserNotificationCenter` — kiểm tra và yêu cầu quyền thông báo

## Navigation

- Routes handled: không xử lý route riêng
- Pushes: `ExportView`, `RecurringTransactionView` (NavigationLink)
- Presents: reset data alert (confirmation dialog)
