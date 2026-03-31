import UIKit

// MARK: - HapticService

// UIKit: haptic feedback requires UINotificationFeedbackGenerator / UIImpactFeedbackGenerator

@MainActor
internal enum HapticService {
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)

    internal static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    internal static func lightImpact() {
        lightGenerator.impactOccurred()
    }

    internal static func mediumImpact() {
        mediumGenerator.impactOccurred()
    }
}
