// MARK: - Purpose: Locale-aware date formatting and month boundary extensions
import Foundation

// MARK: - Localized Date Formatting

internal extension Date {
    /// Active locale from LanguageManager for date formatting
    @MainActor
    private static var activeLocale: Locale {
        LanguageManager.shared.locale
    }

    /// Full date: "Thứ Hai, 15 Tháng 3 2026" (vi) / "Monday, March 15, 2026" (en)
    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()

    @MainActor
    var fullLocalized: String {
        Self.fullDateFormatter.locale = Self.activeLocale
        return Self.fullDateFormatter.string(from: self)
    }

    /// Short date: "15 Tháng 3" (vi) / "15 March" (en)
    @MainActor
    var shortLocalized: String {
        formatted(
            .dateTime
                .day()
                .month(.wide)
                .locale(Self.activeLocale)
        )
    }

    /// Relative: "Hôm nay" / "Hôm qua" or formatted date
    @MainActor
    var relativeLocalized: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return String(localized: "Hôm nay")
        } else if calendar.isDateInYesterday(self) {
            return String(localized: "Hôm qua")
        }
        return shortLocalized
    }

    /// Month + year: "Tháng 3, 2026" (vi) / "March, 2026" (en)
    @MainActor
    var monthYear: String {
        formatted(
            .dateTime
                .month(.wide)
                .year()
                .locale(Self.activeLocale)
        )
    }

    /// "2026-03" for budget monthYear key
    var monthYearKey: String {
        Calendar.current.monthYearKey(for: self)
    }
}

// MARK: - Month Boundary Helpers

internal extension Date {
    /// Start of current month (midnight on the 1st)
    var startOfMonth: Date {
        Calendar.current.startOfMonth(for: self)
    }

    /// End of current month (last second of the last day)
    var endOfMonth: Date {
        Calendar.current.endOfMonth(for: self)
    }
}
