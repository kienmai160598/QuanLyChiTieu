import SwiftUI

// MARK: - Error Banner (M3 Expressive)

/// Renders a styled error banner when `message` is non-nil.
/// M3E: cornerLarge shape for stronger containment.
internal struct ErrorBannerView: View {
    internal let message: String?

    internal var body: some View {
        if let message {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .accessibilityHidden(true)
                Text(message)
                    .font(Typography.bodySmall)
            }
            .foregroundStyle(Color.appError)
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.errorContainer)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerLarge))
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ErrorBannerView(message: "Vui lòng nhập số tiền hợp lệ.")
        ErrorBannerView(message: nil)
    }
    .padding()
}
