// MARK: - Purpose: Runtime language switching with UserDefaults persistence
import Foundation
import SwiftUI

@MainActor @Observable
internal final class LanguageManager {
    internal static let shared = LanguageManager()

    private static let appLanguageKey = "appLanguage"
    private static let appleLanguagesKey = "AppleLanguages"

    internal var currentLanguage: String {
        didSet { persistLanguage(currentLanguage) }
    }

    internal var locale: Locale {
        Locale(identifier: currentLanguage)
    }

    internal var localizedBundle: Bundle {
        guard let path = Bundle.main.path(
            forResource: currentLanguage,
            ofType: "lproj"
        ), let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        return bundle
    }

    private init() {
        let defaults = UserDefaults.standard
        if let saved = defaults.string(forKey: Self.appLanguageKey) {
            currentLanguage = saved
        } else if let appleLanguages = defaults.array(
            forKey: Self.appleLanguagesKey
        ) as? [String], let first = appleLanguages.first {
            currentLanguage = first.hasPrefix("en") ? "en" : "vi"
        } else {
            currentLanguage = "vi"
        }
    }

    private func persistLanguage(_ language: String) {
        let defaults = UserDefaults.standard
        defaults.set(language, forKey: Self.appLanguageKey)
        defaults.set([language], forKey: Self.appleLanguagesKey)
    }
}
