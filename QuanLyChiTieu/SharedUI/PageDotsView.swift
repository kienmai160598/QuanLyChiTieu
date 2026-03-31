import SwiftUI

// MARK: - Page Dots (M3 Expressive)

/// M3E: larger active dot (28pt), solid fills, spatial spring.
internal struct PageDotsView: View {
    internal let currentPage: Int
    internal let totalPages: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<totalPages, id: \.self) { index in
                dotView(index: index, isActive: index == currentPage)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Trang \(currentPage + 1) trên \(totalPages)"))
    }

    private func dotView(index: Int, isActive: Bool) -> some View {
        Capsule()
            .fill(isActive ? Color.appPrimary : Color.outlineVariant.opacity(0.4))
            .frame(width: isActive ? 28 : 8, height: 8)
            .animation(reduceMotion ? .none : Motion.spatialDefault, value: currentPage)
    }
}

#Preview {
    PageDotsView(currentPage: 1, totalPages: 4)
}
