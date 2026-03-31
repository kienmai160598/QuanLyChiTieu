import Foundation

// MARK: - Gold Price Model

internal struct GoldPrice: Identifiable, Sendable {
    internal let id = UUID()
    internal let typeName: String
    internal let buyPrice: Decimal
    internal let sellPrice: Decimal
    internal let change: Decimal
}

// MARK: - Mock Data

internal extension GoldPrice {
    static let mockData: [GoldPrice] = [
        GoldPrice(
            typeName: "SJC 1L - 10L",
            buyPrice: 92_500_000,
            sellPrice: 94_500_000,
            change: 500_000
        ),
        GoldPrice(
            typeName: "SJC 5c",
            buyPrice: 92_500_000,
            sellPrice: 94_700_000,
            change: 300_000
        ),
        GoldPrice(
            typeName: "Nh\u{1EA1}n SJC 99.99",
            buyPrice: 89_500_000,
            sellPrice: 91_000_000,
            change: -200_000
        ),
        GoldPrice(
            typeName: "V\u{00E0}ng n\u{1EEF} trang 24K",
            buyPrice: 88_000_000,
            sellPrice: 89_500_000,
            change: 100_000
        ),
        GoldPrice(
            typeName: "V\u{00E0}ng n\u{1EEF} trang 18K",
            buyPrice: 66_000_000,
            sellPrice: 68_000_000,
            change: 0
        ),
    ]
}
