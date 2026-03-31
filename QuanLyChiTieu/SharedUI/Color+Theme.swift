import SwiftUI

// MARK: - Hex Color Init

internal extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    init(light: String, dark: String) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}

// MARK: - Palette Constants
// Terracotta #C15F3C | Warm Gray #B1ADA1 | Cream #F4F3EE | White #FFFFFF

private let terracotta = "#C15F3C"
private let warmGray = "#B1ADA1"
private let cream = "#F4F3EE"
private let pureWhite = "#FFFFFF"
private let darkText = "#2C2520"
private let lightText = "#FAF9F6"

// MARK: - Semantic Colors

internal extension Color {
    static let appMilk = Color(hex: cream)
    static let appGrayBlue = Color(hex: warmGray)

    // Primary = Terracotta
    static let appPrimary = Color(light: terracotta, dark: "#D4795A")
    static let onPrimary = Color(light: pureWhite, dark: pureWhite)
    static let primaryContainer = Color(light: "#F2DDD5", dark: "#4A2A1E")
    static let onPrimaryContainer = Color(light: darkText, dark: "#F2DDD5")

    // Income = Muted green
    static let appIncome = Color(light: "#5A8A5A", dark: "#7AB87A")

    // Error/Expense = Terracotta (darker shade)
    static let appError = Color(light: "#A84832", dark: "#E07A5E")
    static let onError = Color(light: pureWhite, dark: pureWhite)
    static let errorContainer = Color(light: "#F2DDD5", dark: "#4A2A1E")
    static let onErrorContainer = Color(light: darkText, dark: "#F2DDD5")

    // Secondary = Warm Gray
    static let appSecondary = Color(light: warmGray, dark: "#C8C4BA")
    static let onSecondary = Color(light: pureWhite, dark: darkText)
    static let secondaryContainer = Color(light: "#E8E6E0", dark: "#3A3835")
    static let onSecondaryContainer = Color(light: darkText, dark: "#E8E6E0")

    // Tertiary = Warm Gray (lighter)
    static let appTertiary = Color(light: "#8A8578", dark: "#ACA89C")
    static let onTertiary = Color(light: pureWhite, dark: darkText)
    static let tertiaryContainer = Color(light: "#E8E6E0", dark: "#3A3835")
    static let onTertiaryContainer = Color(light: darkText, dark: "#E8E6E0")

    // Warning = Amber
    static let appWarning = Color(light: "#D4923C", dark: "#E0A850")

    // Surface = Cream / Dark
    static let appSurface = Color(light: cream, dark: "#1A1816")
    static let onSurface = Color(light: darkText, dark: lightText)
    static let surfaceVariant = Color(light: "#EAE8E2", dark: "#302C28")
    static let onSurfaceVariant = Color(light: "#6E6960", dark: "#B5B0A8")

    // Surface Containers (cream → white in light, ascending brightness in dark)
    static let surfaceContainerLowest = Color(light: pureWhite, dark: "#252220")
    static let surfaceContainerLow = Color(light: cream, dark: "#2A2724")
    static let surfaceContainer = Color(light: "#EEEDEA", dark: "#302C28")
    static let surfaceContainerHigh = Color(light: "#E8E6E0", dark: "#3A3835")
    static let surfaceContainerHighest = Color(light: "#DDD9D2", dark: "#454240")

    // Inverse
    static let inverseSurface = Color(light: darkText, dark: lightText)
    static let inverseOnSurface = Color(light: cream, dark: darkText)
    static let inversePrimary = Color(light: "#D4795A", dark: terracotta)

    // Outline
    static let outlineColor = Color(light: warmGray, dark: "#6E6960")
    static let outlineVariant = Color(light: "#D5D2CC", dark: "#3A3835")

    // Accents (warm palette)
    static let accentBlue = Color(light: "#6B8FA3", dark: "#8DB3C7")
    static let accentPink = Color(light: terracotta, dark: "#D4795A")
    static let accentGreen = Color(light: "#5A8A5A", dark: "#7AB87A")
    static let accentYellow = Color(light: "#D4923C", dark: "#E0A850")
    static let accentRed = Color(light: "#A84832", dark: "#E07A5E")
    static let accentPurple = Color(light: "#8A7098", dark: "#AE94BC")
    static let accentOrange = Color(light: terracotta, dark: "#D4795A")

    // Extended
    static let gradientStart = Color(light: terracotta, dark: "#D4795A")
    static let gradientEnd = Color(light: warmGray, dark: "#C8C4BA")
    static let deepSurface = Color(light: darkText, dark: "#0E0C0A")
    static let goldAccent = Color(light: "#D4923C", dark: "#E0A850")

    // Onboarding blobs
    static let blobBlue = Color(light: "#E4EDF2", dark: "#1E2830")
    static let blobGreen = Color(light: "#E2EBE2", dark: "#1E281E")
    static let blobPink = Color(light: "#F2DDD5", dark: "#3A2520")
    static let blobYellow = Color(light: "#F2E8D5", dark: "#3A3020")
    static let blobPurple = Color(light: "#E8E0EE", dark: "#2A2030")
}

// MARK: - Category Colors

internal extension Color {
    static let categoryFood = Color(light: terracotta, dark: "#D4795A")
    static let categoryTransport = Color(light: "#6B8FA3", dark: "#8DB3C7")
    static let categoryShopping = Color(light: "#D4923C", dark: "#E0A850")
    static let categoryEntertainment = Color(light: "#5A8A5A", dark: "#7AB87A")
    static let categoryBills = Color(light: "#8A7098", dark: "#AE94BC")
    static let categoryHealth = Color(light: "#6B8FA3", dark: "#8DB3C7")
}
