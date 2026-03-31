import SwiftUI

// MARK: - Save Button (M3 Expressive CTA)

/// Full-width capsule CTA with solid background.
/// Disabled state renders at reduced opacity.
internal struct GlassSaveButton: View {
    internal let label: String
    internal let isEnabled: Bool
    internal let tintColor: Color
    internal let action: () -> Void

    internal init(
        label: String,
        isEnabled: Bool,
        tintColor: Color = .appPrimary,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.isEnabled = isEnabled
        self.tintColor = tintColor
        self.action = action
    }

    internal var body: some View {
        Button(action: action) {
            Text(label)
                .font(Typography.labelLargeEmphasized)
                .foregroundStyle(Color.onPrimary)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(tintColor, in: Capsule())
                .opacity(isEnabled ? 1.0 : 0.4)
        }
        .buttonStyle(ExpressivePressStyle())
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        GlassSaveButton(label: "Tạo ngân sách", isEnabled: true) {}
        GlassSaveButton(label: "Tạo ngân sách", isEnabled: false) {}
    }
    .padding()
}
