import SwiftUI

// MARK: - Chip Item

internal struct ChipItem: Identifiable, Sendable {
    internal let id: String
    internal let label: String
    internal let icon: String?

    internal init(id: String, label: String, icon: String? = nil) {
        self.id = id
        self.label = label
        self.icon = icon
    }
}

// MARK: - Chip Group (M3 Expressive)

/// Horizontal filter chip row.
/// M3E: selected = filled primary capsule, unselected = outlined rounded rect.
internal struct GlassChipGroup: View {
    internal let items: [ChipItem]
    @Binding internal var selectedID: String?

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    internal var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(items) { item in
                    chipButton(for: item)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xs)
        }
        .animation(
            reduceMotion ? .none : Motion.spatialDefault,
            value: selectedID
        )
    }

    private func chipButton(for item: ChipItem) -> some View {
        let isSelected = selectedID == item.id

        return Button {
            triggerHaptic()
            selectedID = isSelected ? nil : item.id
        } label: {
            chipLabel(for: item, isSelected: isSelected)
        }
        .buttonStyle(ExpressivePressStyle())
        .accessibilityLabel(item.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func chipLabel(
        for item: ChipItem,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: Spacing.xs) {
            if let icon = item.icon {
                Image(systemName: icon)
                    .font(isSelected ? Typography.bodySmallEmphasized : Typography.bodySmall)
            }
            Text(item.label)
                .font(isSelected ? Typography.bodySmallEmphasized : Typography.bodySmall)
        }
        .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurfaceVariant)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            isSelected ? Color.appPrimary : Color.surfaceContainerHigh,
            in: isSelected
                ? AnyShape(.capsule)
                : AnyShape(RoundedRectangle(cornerRadius: Spacing.cornerMedium, style: .continuous))
        )
        .overlay {
            if !isSelected {
                RoundedRectangle(cornerRadius: Spacing.cornerMedium, style: .continuous)
                    .strokeBorder(Color.outlineVariant, lineWidth: 1)
            }
        }
    }

    private func triggerHaptic() {
        HapticService.lightImpact()
    }
}

#Preview {
    @Previewable @State var selected: String? = "food"

    let chips: [ChipItem] = [
        ChipItem(id: "all", label: "Tất cả", icon: "square.grid.2x2"),
        ChipItem(id: "food", label: "Ăn uống", icon: "fork.knife"),
        ChipItem(id: "transport", label: "Di chuyển", icon: "car"),
        ChipItem(id: "shopping", label: "Mua sắm", icon: "bag"),
    ]

    GlassChipGroup(items: chips, selectedID: $selected)
}
