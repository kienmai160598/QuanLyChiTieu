import SwiftUI

// MARK: - Preset Icons & Colors for Savings Goals

internal enum IconColorPickerDefaults {
    internal static let availableIcons: [String] = [
        "fork.knife", "car.fill", "bag.fill", "heart.fill",
        "house.fill", "book.fill", "gamecontroller.fill", "gift.fill",
        "banknote.fill", "doc.text.fill", "cross.fill", "airplane",
        "tram.fill", "cart.fill", "graduationcap.fill", "paintbrush.fill",
        "wrench.fill", "music.note", "film.fill", "person.2.fill",
    ]

    internal static let presetColors: [String] = [
        "#D7A49A", "#A4B1BA", "#B5B89A", "#E4C9B6",
        "#E1DAD3", "#C4877D", "#8A97A0", "#3D3633",
    ]
}

// MARK: - Icon Color Picker View

/// M3E: reusable icon and color picker for customizing savings goals.
/// Uses capsule shape for selected state per M3 Expressive guidelines.
internal struct IconColorPicker: View {
    @Binding internal var selectedIcon: String
    @Binding internal var selectedColorHex: String

    internal let availableIcons: [String]
    internal let presetColors: [String]

    internal init(
        selectedIcon: Binding<String>,
        selectedColorHex: Binding<String>,
        availableIcons: [String] = IconColorPickerDefaults.availableIcons,
        presetColors: [String] = IconColorPickerDefaults.presetColors
    ) {
        _selectedIcon = selectedIcon
        _selectedColorHex = selectedColorHex
        self.availableIcons = availableIcons
        self.presetColors = presetColors
    }

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            iconPicker
            Divider()
            colorPicker
        }
        .padding(Spacing.lg)
        .m3Card()
    }
}

// MARK: - Icon Picker Section

private extension IconColorPicker {
    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Biểu tượng"))
                .font(Typography.labelMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 5),
                spacing: Spacing.sm
            ) {
                ForEach(availableIcons, id: \.self) { icon in
                    iconCell(icon)
                }
            }
        }
    }

    private func iconCell(_ icon: String) -> some View {
        let isSelected = selectedIcon == icon
        return Button {
            withAnimation(Motion.spatialFast) {
                selectedIcon = icon
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: IconSize.md, weight: .medium))
                .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurfaceVariant)
                .frame(width: 44, height: 44)
                .background(
                    isSelected ? Color.appPrimary : Color.surfaceContainerHigh,
                    in: RoundedRectangle(
                        cornerRadius: isSelected ? Spacing.cornerMedium : Spacing.cornerSmall
                    )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Color Picker Section

private extension IconColorPicker {
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Màu sắc"))
                .font(Typography.labelMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            HStack(spacing: Spacing.md) {
                ForEach(presetColors, id: \.self) { hex in
                    colorCell(hex)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func colorCell(_ hex: String) -> some View {
        let isSelected = selectedColorHex == hex
        return Button {
            withAnimation(Motion.spatialFast) {
                selectedColorHex = hex
            }
        } label: {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 32, height: 32)
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .overlay {
                    if isSelected {
                        Circle().strokeBorder(Color.onSurface, lineWidth: 2.5)
                            .frame(width: 32, height: 32)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(hex)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var icon = "heart.fill"
    @Previewable @State var color = "#D7A49A"

    IconColorPicker(selectedIcon: $icon, selectedColorHex: $color)
        .padding()
        .appBackground()
}
