import SwiftUI

// MARK: - GoldPriceView

internal struct GoldPriceView: View {
    @State private var viewModel = GoldPriceViewModel()

    internal var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                headerCard
                priceCards
                footerNote
            }
            .padding(Spacing.lg)
        }
        .appBackground()
        .navigationTitle(String(localized: "Gi\u{00E1} v\u{00E0}ng SJC"))
        .task { await viewModel.loadPrices() }
    }
}

// MARK: - Header

private extension GoldPriceView {
    private var headerCard: some View {
        VStack(spacing: Spacing.sm) {
            headerTitle
            if !viewModel.lastUpdated.isEmpty {
                Text(viewModel.lastUpdated)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            columnHeaders
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge)
    }

    private var headerTitle: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(Typography.headlineSmall)
                .foregroundStyle(Color.goldAccent)
            Text(String(localized: "Gi\u{00E1} v\u{00E0}ng SJC"))
                .font(Typography.headlineSmall)
                .foregroundStyle(Color.onSurface)
        }
    }

    private var columnHeaders: some View {
        HStack {
            Text(String(localized: "Lo\u{1EA1}i"))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(localized: "Mua"))
                .frame(width: 80, alignment: .trailing)
            Text(String(localized: "B\u{00E1}n"))
                .frame(width: 80, alignment: .trailing)
            Text(String(localized: "+/-"))
                .frame(width: 60, alignment: .trailing)
        }
        .font(Typography.labelMedium)
        .foregroundStyle(Color.onSurfaceVariant)
        .padding(.top, Spacing.xs)
    }
}

// MARK: - Price Cards

private extension GoldPriceView {
    @ViewBuilder
    private var priceCards: some View {
        if viewModel.isLoading {
            loadingContent
        } else {
            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.prices) { price in
                    priceRow(for: price)
                }
            }
            .padding(Spacing.lg)
            .m3Card(cornerRadius: Spacing.cornerExtraLarge)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
            Text(String(localized: "\u{0110}ang t\u{1EA3}i d\u{1EEF} li\u{1EC7}u..."))
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxxl)
    }

    private func priceRow(for price: GoldPrice) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Text(price.typeName)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Color.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                compactPrice(price.buyPrice)
                    .frame(width: 80, alignment: .trailing)
                compactPrice(price.sellPrice)
                    .frame(width: 80, alignment: .trailing)
                changeLabel(for: price.change)
                    .frame(width: 60, alignment: .trailing)
            }
            if price.id != viewModel.prices.last?.id {
                Divider()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(priceAccessibilityLabel(for: price))
    }
}

// MARK: - Price Formatting Helpers

private extension GoldPriceView {
    private func compactPrice(_ value: Decimal) -> some View {
        Text(value.compactVND)
            .font(Typography.bodySmall)
            .monospacedDigit()
            .foregroundStyle(Color.onSurface)
            .lineLimit(1)
    }

    private func changeLabel(for change: Decimal) -> some View {
        HStack(spacing: Spacing.xxs) {
            if change > 0 {
                Image(systemName: "arrow.up")
                    .font(.caption2)
            } else if change < 0 {
                Image(systemName: "arrow.down")
                    .font(.caption2)
            }
            Text(changeText(for: change))
                .font(Typography.labelSmall)
                .monospacedDigit()
        }
        .foregroundStyle(changeColor(for: change))
        .lineLimit(1)
    }

    private func changeText(for change: Decimal) -> String {
        let absolute = abs(change)
        if absolute == 0 { return "-" }
        return absolute.compactVND
    }

    private func changeColor(for change: Decimal) -> Color {
        if change > 0 { return Color.accentGreen }
        if change < 0 { return Color.accentRed }
        return Color.onSurfaceVariant
    }

    private func priceAccessibilityLabel(for price: GoldPrice) -> String {
        let buy = price.buyPrice.formattedVND
        let sell = price.sellPrice.formattedVND
        return "\(price.typeName), mua \(buy), b\u{00E1}n \(sell)"
    }
}

// MARK: - Footer

private extension GoldPriceView {
    private var footerNote: some View {
        Text(String(localized: "D\u{1EEF} li\u{1EC7}u m\u{1EAB}u \u{2014} k\u{1EBF}t n\u{1ED1}i API s\u{1EBD} \u{0111}\u{01B0}\u{1EE3}c th\u{00EA}m sau"))
            .font(Typography.labelSmall)
            .foregroundStyle(Color.outlineVariant)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.sm)
    }
}
