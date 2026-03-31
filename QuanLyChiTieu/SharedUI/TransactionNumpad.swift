import SwiftUI

// MARK: - TransactionNumpad (M3 Expressive)

internal struct TransactionNumpad: View {
    internal let onDigit: (String) -> Void
    internal let onDelete: () -> Void

    private static let rows: [[NumpadKey]] = [
        [.digit("1"), .digit("2"), .digit("3")],
        [.digit("4"), .digit("5"), .digit("6")],
        [.digit("7"), .digit("8"), .digit("9")],
        [.empty, .digit("0"), .delete]
    ]

    internal var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(Self.rows.indices, id: \.self) { rowIndex in
                HStack(spacing: Spacing.sm) {
                    ForEach(Self.rows[rowIndex].indices, id: \.self) { colIndex in
                        numpadButton(Self.rows[rowIndex][colIndex])
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.surfaceContainerLow)
    }
}

// MARK: - Numpad Key Model

private enum NumpadKey {
    case digit(String)
    case delete
    case empty
}

// MARK: - Numpad Buttons

private extension TransactionNumpad {
    @ViewBuilder
    private func numpadButton(_ key: NumpadKey) -> some View {
        switch key {
        case .digit(let value):
            digitButton(value)
        case .delete:
            deleteButton
        case .empty:
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 56)
        }
    }

    private func digitButton(_ value: String) -> some View {
        Button {
            HapticService.lightImpact()
            onDigit(value)
        } label: {
            Text(value)
                .font(Typography.headlineMedium)
                .foregroundStyle(Color.onSurface)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color.surfaceContainerHigh)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerLarge))
        }
        .buttonStyle(NumpadPressStyle())
        .accessibilityLabel(value)
    }

    private var deleteButton: some View {
        Button {
            HapticService.lightImpact()
            onDelete()
        } label: {
            Image(systemName: "delete.backward")
                .font(.title3)
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color.surfaceContainerHigh)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerLarge))
        }
        .buttonStyle(NumpadPressStyle())
        .accessibilityLabel(String(localized: "Xoa"))
        .onLongPressGesture(minimumDuration: 0.4) {
            HapticService.mediumImpact()
            onDelete()
        }
    }
}

// MARK: - M3 Expressive Numpad Press Style

private struct NumpadPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? 0.92 : 1.0))
            .animation(
                reduceMotion ? .none : Motion.spatialFast,
                value: configuration.isPressed
            )
    }
}

// MARK: - Preview

#Preview {
    TransactionNumpad(
        onDigit: { _ in },
        onDelete: {}
    )
}
