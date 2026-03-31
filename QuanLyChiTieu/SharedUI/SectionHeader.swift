import SwiftUI

// MARK: - Reusable section header with optional trailing view (M3 Expressive)

/// M3E: emphasized titleMedium for stronger visual hierarchy.
internal struct SectionHeader<Trailing: View>: View {
    private let title: LocalizedStringKey
    private let trailing: () -> Trailing

    internal init(
        _ title: LocalizedStringKey,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.trailing = trailing
    }

    internal var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Typography.titleMediumEmphasized)
                .foregroundStyle(Color.onSurface)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            trailing()
        }
    }
}
