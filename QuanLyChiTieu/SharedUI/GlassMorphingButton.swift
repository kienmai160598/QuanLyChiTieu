import SwiftUI

// MARK: - Morphing Button (M3 Expressive)

/// A button that morphs between a compact circle (FAB) and an expanded
/// capsule with text, using `matchedGeometryEffect` for smooth transitions.
/// M3E: solid fill, spring motion with bounce, emphasized font.
internal struct GlassMorphingButton: View {
    internal let compactIcon: String
    internal let expandedTitle: String
    internal let isExpanded: Bool
    internal let namespace: Namespace.ID
    internal let morphID: String
    internal let tintColor: Color
    internal let action: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    internal init(
        compactIcon: String,
        expandedTitle: String,
        isExpanded: Bool,
        namespace: Namespace.ID,
        morphID: String,
        tintColor: Color = .primaryContainer,
        action: @escaping () -> Void
    ) {
        self.compactIcon = compactIcon
        self.expandedTitle = expandedTitle
        self.isExpanded = isExpanded
        self.namespace = namespace
        self.morphID = morphID
        self.tintColor = tintColor
        self.action = action
    }

    internal var body: some View {
        Button {
            triggerHaptic()
            action()
        } label: {
            buttonContent
                .background(tintColor, in: morphShape)
        }
        .buttonStyle(ExpressivePressStyle())
        .accessibilityLabel(expandedTitle)
        .animation(
            reduceMotion ? .none : Motion.spatialDefault,
            value: isExpanded
        )
    }

    private var morphShape: some Shape {
        isExpanded
            ? AnyShape(.capsule)
            : AnyShape(.circle)
    }

    @ViewBuilder
    private var buttonContent: some View {
        if isExpanded {
            expandedLabel
        } else {
            compactLabel
        }
    }

    private var compactLabel: some View {
        Image(systemName: compactIcon)
            .font(.title2.weight(.semibold))
            .foregroundStyle(Color.onPrimaryContainer)
            .frame(width: IconSize.containerHero, height: IconSize.containerHero)
    }

    private var expandedLabel: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: compactIcon)
                .font(Typography.bodyLargeEmphasized)
            Text(expandedTitle)
                .font(Typography.bodyLargeEmphasized)
        }
        .foregroundStyle(Color.onPrimaryContainer)
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.lg)
    }

    private func triggerHaptic() {
        HapticService.mediumImpact()
    }
}

#Preview {
    @Previewable @Namespace var ns
    @Previewable @State var expanded = false

    VStack {
        Spacer()
        HStack {
            Spacer()
            GlassMorphingButton(
                compactIcon: "plus",
                expandedTitle: "Thêm chi tiêu",
                isExpanded: expanded,
                namespace: ns,
                morphID: "addButton",
                action: { expanded.toggle() }
            )
            .padding()
        }
    }
}
