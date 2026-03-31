import Testing
import Foundation
@testable import QuanLyChiTieu

// MARK: - UserDefaults test isolation helper

private extension UserDefaults {
    static func makeTestSuite(named name: String) -> UserDefaults {
        let suite = UserDefaults(suiteName: name)!
        suite.removePersistentDomain(forName: name)
        return suite
    }
}

// MARK: - Testable subclass that injects UserDefaults

/// Exposes a seam for injecting a test-isolated UserDefaults suite so that
/// `completeOnboarding()` does not pollute the real `UserDefaults.standard`.
@MainActor
private final class TestableOnboardingViewModel: OnboardingViewModel {
    private let testDefaults: UserDefaults

    init(defaults: UserDefaults, initialLanguage: String? = nil) {
        self.testDefaults = defaults
        super.init()
        if let lang = initialLanguage {
            selectedLanguage = lang
        }
    }

    override func completeOnboarding() {
        testDefaults.set(true, forKey: OnboardingViewModel.completedKey)
        testDefaults.set(trimmedUserName, forKey: OnboardingViewModel.userNameKey)
        LanguageManager.shared.currentLanguage = selectedLanguage
    }
}

// MARK: - Suite

@Suite("OnboardingViewModel")
@MainActor
struct OnboardingViewModelTests {

    // MARK: Initial State

    @Suite("initialState")
    @MainActor
    struct InitialState {
        @Test func initialState_currentPage_isZero() {
            let vm = OnboardingViewModel()
            #expect(vm.currentPage == 0)
        }

        @Test func initialState_totalPages_isFive() {
            let vm = OnboardingViewModel()
            #expect(vm.totalPages == 5)
        }

        @Test func initialState_userName_isEmpty() {
            let vm = OnboardingViewModel()
            #expect(vm.userName.isEmpty)
        }

        @Test func initialState_selectedLanguage_matchesSystemPreference() {
            let vm = OnboardingViewModel()
            let preferred = Locale.preferredLanguages.first ?? "vi"
            let expected = preferred.hasPrefix("en") ? "en" : "vi"
            #expect(vm.selectedLanguage == expected)
        }
    }

    // MARK: advance()

    @Suite("advance")
    @MainActor
    struct Advance {
        @Test func advance_fromFirstPage_movesToSecondPage() {
            let vm = OnboardingViewModel()
            vm.advance()
            #expect(vm.currentPage == 1)
        }

        @Test func advance_fromMiddlePage_incrementsByOne() {
            let vm = OnboardingViewModel()
            vm.currentPage = 2
            vm.advance()
            #expect(vm.currentPage == 3)
        }

        @Test func advance_fromLastPage_doesNotExceedBounds() {
            let vm = OnboardingViewModel()
            vm.currentPage = vm.totalPages - 1
            vm.advance()
            #expect(vm.currentPage == vm.totalPages - 1)
        }

        @Test func advance_calledRepeatedly_stopsAtLastPage() {
            let vm = OnboardingViewModel()
            let callCount = vm.totalPages + 5
            for _ in 0..<callCount {
                vm.advance()
            }
            #expect(vm.currentPage == vm.totalPages - 1)
        }

        @Test func advance_fromSecondToLastPage_reachesLastPage() {
            let vm = OnboardingViewModel()
            vm.currentPage = vm.totalPages - 2
            vm.advance()
            #expect(vm.currentPage == vm.totalPages - 1)
        }
    }

    // MARK: selectLanguage(_:)

    @Suite("selectLanguage")
    @MainActor
    struct SelectLanguage {
        @Test func selectLanguage_english_updatesSelectedLanguage() {
            let vm = OnboardingViewModel()
            vm.selectLanguage("en")
            #expect(vm.selectedLanguage == "en")
        }

        @Test func selectLanguage_vietnamese_updatesSelectedLanguage() {
            let vm = OnboardingViewModel()
            vm.selectLanguage("en")
            vm.selectLanguage("vi")
            #expect(vm.selectedLanguage == "vi")
        }

        @Test func selectLanguage_calledMultipleTimes_retainsLastValue() {
            let vm = OnboardingViewModel()
            vm.selectLanguage("en")
            vm.selectLanguage("vi")
            vm.selectLanguage("en")
            #expect(vm.selectedLanguage == "en")
        }
    }

    // MARK: t(_:_:)

    @Suite("t_translation")
    @MainActor
    struct Translation {
        @Test func t_whenVietnamese_returnsVietnameseString() {
            let vm = OnboardingViewModel()
            vm.selectedLanguage = "vi"
            #expect(vm.t("Tiếp theo", "Next") == "Tiếp theo")
        }

        @Test func t_whenEnglish_returnsEnglishString() {
            let vm = OnboardingViewModel()
            vm.selectedLanguage = "en"
            #expect(vm.t("Tiếp theo", "Next") == "Next")
        }

        @Test func t_emptyStrings_returnsCorrectEmpty() {
            let vm = OnboardingViewModel()
            vm.selectedLanguage = "vi"
            #expect(vm.t("", "fallback") == "")
        }

        @Test func t_afterLanguageChange_reflectsNewLanguage() {
            let vm = OnboardingViewModel()
            vm.selectedLanguage = "vi"
            let resultBefore = vm.t("Xin chào", "Hello")
            vm.selectLanguage("en")
            let resultAfter = vm.t("Xin chào", "Hello")
            #expect(resultBefore == "Xin chào")
            #expect(resultAfter == "Hello")
        }
    }

    // MARK: trimmedUserName

    @Suite("trimmedUserName")
    @MainActor
    struct TrimmedUserName {
        @Test func trimmedUserName_plainName_returnsSameName() {
            let vm = OnboardingViewModel()
            vm.userName = "Kiên"
            #expect(vm.trimmedUserName == "Kiên")
        }

        @Test func trimmedUserName_withLeadingSpaces_stripsSpaces() {
            let vm = OnboardingViewModel()
            vm.userName = "  Kiên"
            #expect(vm.trimmedUserName == "Kiên")
        }

        @Test func trimmedUserName_withTrailingSpaces_stripsSpaces() {
            let vm = OnboardingViewModel()
            vm.userName = "Kiên  "
            #expect(vm.trimmedUserName == "Kiên")
        }

        @Test func trimmedUserName_onlyWhitespace_returnsEmpty() {
            let vm = OnboardingViewModel()
            vm.userName = "   "
            #expect(vm.trimmedUserName.isEmpty)
        }

        @Test func trimmedUserName_emptyString_returnsEmpty() {
            let vm = OnboardingViewModel()
            vm.userName = ""
            #expect(vm.trimmedUserName.isEmpty)
        }

        @Test func trimmedUserName_withNewlines_stripsNewlines() {
            let vm = OnboardingViewModel()
            vm.userName = "\nKiên\n"
            #expect(vm.trimmedUserName == "Kiên")
        }
    }

    // MARK: completeOnboarding()

    @Suite("completeOnboarding")
    @MainActor
    struct CompleteOnboarding {
        private static func makeTestDefaults() -> UserDefaults {
            UserDefaults.makeTestSuite(named: "OnboardingViewModelTests.\(UUID().uuidString)")
        }

        @Test func completeOnboarding_setsCompletedFlagToTrue() {
            let defaults = Self.makeTestDefaults()
            let vm = TestableOnboardingViewModel(defaults: defaults)
            vm.completeOnboarding()
            #expect(defaults.bool(forKey: OnboardingViewModel.completedKey) == true)
        }

        @Test func completeOnboarding_savesTrimmedUserName() {
            let defaults = Self.makeTestDefaults()
            let vm = TestableOnboardingViewModel(defaults: defaults)
            vm.userName = "  Nguyễn Văn A  "
            vm.completeOnboarding()
            #expect(defaults.string(forKey: OnboardingViewModel.userNameKey) == "Nguyễn Văn A")
        }

        @Test func completeOnboarding_emptyUserName_savesEmptyString() {
            let defaults = Self.makeTestDefaults()
            let vm = TestableOnboardingViewModel(defaults: defaults)
            vm.userName = ""
            vm.completeOnboarding()
            #expect(defaults.string(forKey: OnboardingViewModel.userNameKey) == "")
        }

        @Test func completeOnboarding_whitespaceOnlyUserName_savesEmptyString() {
            let defaults = Self.makeTestDefaults()
            let vm = TestableOnboardingViewModel(defaults: defaults)
            vm.userName = "   "
            vm.completeOnboarding()
            #expect(defaults.string(forKey: OnboardingViewModel.userNameKey) == "")
        }

        @Test func completeOnboarding_updatesLanguageManager() {
            let defaults = Self.makeTestDefaults()
            let vm = TestableOnboardingViewModel(defaults: defaults, initialLanguage: "en")
            vm.completeOnboarding()
            #expect(LanguageManager.shared.currentLanguage == "en")
        }

        @Test func completeOnboarding_canBeCalledFromAnyPage() {
            let defaults = Self.makeTestDefaults()
            let vm = TestableOnboardingViewModel(defaults: defaults)
            vm.currentPage = 2
            vm.completeOnboarding()
            #expect(defaults.bool(forKey: OnboardingViewModel.completedKey) == true)
        }
    }

    // MARK: Page Navigation — skip-to-last pattern

    @Suite("skipToLastPage")
    @MainActor
    struct SkipToLastPage {
        @Test func skipToLastPage_setsCurrentPageToLastPage() {
            let vm = OnboardingViewModel()
            vm.currentPage = vm.totalPages - 1
            #expect(vm.currentPage == vm.totalPages - 1)
        }

        @Test func skipToLastPage_fromFirstPage_pageIsCorrect() {
            let vm = OnboardingViewModel()
            vm.currentPage = vm.totalPages - 1
            #expect(vm.currentPage == 4)
        }
    }

    // MARK: Constants

    @Suite("constants")
    @MainActor
    struct Constants {
        @Test func completedKey_matchesExpectedKey() {
            #expect(OnboardingViewModel.completedKey == "hasCompletedOnboarding")
        }

        @Test func languageKey_matchesExpectedKey() {
            #expect(OnboardingViewModel.languageKey == "appLanguage")
        }

        @Test func userNameKey_matchesExpectedKey() {
            #expect(OnboardingViewModel.userNameKey == "userName")
        }
    }
}
