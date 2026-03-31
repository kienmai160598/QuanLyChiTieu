import SwiftUI

// MARK: - App Background

internal struct AppBackground: View {
    internal var body: some View {
        ZStack {
            Color.appSurface
            gradient
        }
        .ignoresSafeArea()
    }

    private var gradient: some View {
        LinearGradient(
            stops: [
                .init(color: Color.primaryContainer.opacity(0.25), location: 0),
                .init(color: Color.primaryContainer.opacity(0.10), location: 0.35),
                .init(color: Color.appSurface.opacity(0), location: 0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View Modifier

internal extension View {
    func appBackground() -> some View {
        background { AppBackground() }
    }
}
