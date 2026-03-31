import SwiftUI

// MARK: - Reusable Toolbar (M3 Expressive)

/// Wraps toolbar content in an HStack with consistent spacing/padding.
internal struct GlassToolbar<Content: View>: View {
    private let spacing: CGFloat
    private let content: () -> Content

    internal init(
        spacing: CGFloat = 12,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.content = content
    }

    internal var body: some View {
        HStack(spacing: spacing) {
            content()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }
}

#Preview {
    GlassToolbar {
        Button {
        } label: {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(width: 44, height: 44)
                .background(Color.surfaceContainerHigh, in: .circle)
        }

        Spacer()

        Button {
        } label: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.onPrimary)
                .frame(width: 44, height: 44)
                .background(Color.appPrimary, in: .circle)
        }
    }
}
