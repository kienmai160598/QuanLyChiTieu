import SwiftUI

@MainActor @Observable
internal final class OnboardingViewModel {
    internal static let completedKey = "hasCompletedOnboarding"
    internal static let languageKey = "appLanguage"
    internal static let userNameKey = "userName"

    internal var currentPage: Int = 0
    internal let totalPages: Int = 5
    internal var selectedLanguage: String = "vi"
    internal var userName: String = ""

    internal init() {
        let preferred = Locale.preferredLanguages.first ?? "vi"
        selectedLanguage = preferred.hasPrefix("en") ? "en" : "vi"
    }

    internal func advance() {
        guard currentPage < totalPages - 1 else { return }
        currentPage += 1
    }

    internal func selectLanguage(_ code: String) {
        selectedLanguage = code
    }

    internal func t(_ vi: String, _ en: String) -> String {
        selectedLanguage == "en" ? en : vi
    }

    internal var trimmedUserName: String {
        userName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    internal func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.completedKey)
        UserDefaults.standard.set(trimmedUserName, forKey: Self.userNameKey)
        LanguageManager.shared.currentLanguage = selectedLanguage
    }
}
