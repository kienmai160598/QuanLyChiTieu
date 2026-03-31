import Foundation

// TODO: Replace with real SJC API -- certificate pinning required per security rules

@MainActor @Observable
internal final class GoldPriceViewModel {
    internal var prices: [GoldPrice] = []
    internal var isLoading: Bool = false
    internal var lastUpdated: String = ""

    // MARK: - Actions

    internal func loadPrices() async {
        isLoading = true
        defer { isLoading = false }

        // Simulate network delay for mock data
        try? await Task.sleep(for: .milliseconds(600))

        prices = GoldPrice.mockData
        lastUpdated = formatLastUpdated()
    }
}

// MARK: - Private Helpers

private extension GoldPriceViewModel {
    private func formatLastUpdated() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "HH:mm dd/MM/yyyy"
        return String(
            localized: "C\u{1EAD}p nh\u{1EAD}t l\u{00FA}c \(formatter.string(from: .now))"
        )
    }
}
