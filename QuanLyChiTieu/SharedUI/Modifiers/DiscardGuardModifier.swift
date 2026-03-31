import SwiftUI

// MARK: - Discard Guard Modifier

/// Prevents accidental dismissal when unsaved changes exist.
/// Disables interactive dismiss and presents an alert asking
/// the user to confirm discarding or continuing to edit.
internal struct DiscardGuardModifier: ViewModifier {
    internal let hasChanges: Bool
    @Binding internal var showAlert: Bool
    @Environment(\.dismiss) private var dismiss

    internal func body(content: Content) -> some View {
        content
            .interactiveDismissDisabled(hasChanges)
            .alert(
                String(localized: "Huỷ thay đổi?"),
                isPresented: $showAlert
            ) {
                Button(String(localized: "Tiếp tục chỉnh sửa"), role: .cancel) {}
                Button(String(localized: "Huỷ"), role: .destructive) { dismiss() }
            } message: {
                Text(String(localized: "Bạn có thay đổi chưa lưu. Bạn có chắc muốn huỷ?"))
            }
    }
}

// MARK: - View Extension

internal extension View {
    /// Prevents interactive dismiss and shows a discard-confirmation alert
    /// when `hasChanges` is true. Bind `showAlert` to the local state variable
    /// that the cancel button sets to `true`.
    func discardGuard(hasChanges: Bool, showAlert: Binding<Bool>) -> some View {
        modifier(DiscardGuardModifier(hasChanges: hasChanges, showAlert: showAlert))
    }
}
