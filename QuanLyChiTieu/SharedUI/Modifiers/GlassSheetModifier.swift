import SwiftUI

// MARK: - M3 Expressive Sheet Modifier

/// Presents a sheet with M3E surface background styling.
internal struct GlassSheetModifier<SheetContent: View>: ViewModifier {
    @Binding internal var isPresented: Bool
    internal let detents: Set<PresentationDetent>
    internal let onDismiss: (() -> Void)?
    internal let sheetContent: () -> SheetContent

    internal init(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.large],
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder sheetContent: @escaping () -> SheetContent
    ) {
        self._isPresented = isPresented
        self.detents = detents
        self.onDismiss = onDismiss
        self.sheetContent = sheetContent
    }

    internal func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                sheetContent()
                    .presentationDetents(detents)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
                    .presentationBackground(Color.surfaceContainerLowest)
            }
    }
}

// MARK: - View Extension

internal extension View {
    func glassSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.large],
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(
            GlassSheetModifier(
                isPresented: isPresented,
                detents: detents,
                onDismiss: onDismiss,
                sheetContent: content
            )
        )
    }
}

#Preview {
    @Previewable @State var showSheet = false

    Button("Mở sheet") {
        showSheet = true
    }
    .glassSheet(isPresented: $showSheet) {
        VStack(spacing: 16) {
            Text("Thêm chi tiêu")
                .font(.title2.weight(.bold))
            Text("Nhập thông tin chi tiêu mới")
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .padding()
    }
}
