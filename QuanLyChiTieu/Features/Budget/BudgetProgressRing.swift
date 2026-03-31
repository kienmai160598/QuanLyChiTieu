import SwiftUI

// MARK: - Reusable circular progress ring for budget screens

internal struct BudgetProgressRing: View {
    internal let progress: Double
    internal let tintColor: Color
    internal let label: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal var body: some View {
        ZStack {
            Circle()
                .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 10)
                .frame(width: 120, height: 120)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tintColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(
                    reduceMotion ? .none : Motion.effectDefault,
                    value: progress
                )
            VStack(spacing: Spacing.xs) {
                Text("\(Int(progress * 100))%")
                    .font(Typography.headlineSmall)
                    .foregroundStyle(Color.onSurface)
                    .contentTransition(.numericText())
                Text(String(localized: "đã chi"))
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(String(localized: "\(Int(progress * 100)) phần trăm đã chi"))
    }
}
