import SwiftData
import Foundation

// MARK: - Profile Setup ViewModel

@MainActor @Observable
internal final class ProfileSetupViewModel {

    // MARK: - Form State

    internal var name: String = ""
    internal var selectedGender: Gender?
    internal var birthday: Date = Calendar.current.date(
        byAdding: .year, value: -20, to: Date()
    ) ?? Date()
    internal var hasBirthday: Bool = false
    internal var phoneNumber: String = ""

    // MARK: - Error State

    internal var saveErrorMessage: String?

    // MARK: - Original Values

    private var originalName: String = ""
    private var originalGender: Gender?
    private var originalBirthday: Date?
    private var originalHasBirthday: Bool = false
    private var originalPhoneNumber: String = ""

    // MARK: - Change Detection

    internal var hasChanges: Bool {
        name != originalName
            || selectedGender != originalGender
            || hasBirthday != originalHasBirthday
            || (hasBirthday && birthday != (originalBirthday ?? birthday))
            || phoneNumber != originalPhoneNumber
    }

    // MARK: - Load

    internal func loadExistingData(
        profiles: [UserProfile],
        authService: AuthService
    ) {
        let profile = profiles.first
        name = authService.currentUserName
            ?? profile?.displayName
            ?? UserDefaults.standard.string(forKey: "userName")
            ?? ""
        selectedGender = profile?.genderEnum
        if let bd = profile?.birthday {
            birthday = bd
            hasBirthday = true
        }
        phoneNumber = profile?.phoneNumber ?? ""
        storeOriginalValues()
    }

    // MARK: - Private

    private func storeOriginalValues() {
        originalName = name
        originalGender = selectedGender
        originalBirthday = hasBirthday ? birthday : nil
        originalHasBirthday = hasBirthday
        originalPhoneNumber = phoneNumber
    }

    // MARK: - Save

    internal func saveProfile(
        profiles: [UserProfile],
        authService: AuthService,
        context: ModelContext
    ) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        UserDefaults.standard.set(trimmed, forKey: "userName")

        updateOrCreateProfile(
            trimmed: trimmed,
            profiles: profiles,
            authService: authService,
            context: context
        )

        do {
            try context.save()
            return true
        } catch {
            saveErrorMessage = String(localized: "Không thể lưu hồ sơ. Vui lòng thử lại.")
            return false
        }
    }

    // MARK: - Validation

    internal var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

// MARK: - Private Helpers

private extension ProfileSetupViewModel {
    func updateOrCreateProfile(
        trimmed: String,
        profiles: [UserProfile],
        authService: AuthService,
        context: ModelContext
    ) {
        if let profile = profiles.first {
            profile.displayName = trimmed
            profile.genderEnum = selectedGender
            profile.birthday = hasBirthday ? birthday : nil
            profile.phoneNumber = phoneNumber.isEmpty
                ? nil : phoneNumber
        } else if authService.isSignedIn,
                  let uid = authService.currentUID {
            let profile = UserProfile(
                uid: uid,
                displayName: trimmed,
                email: authService.currentUserEmail,
                provider: authService.currentProviderID,
                gender: selectedGender?.rawValue,
                birthday: hasBirthday ? birthday : nil,
                phoneNumber: phoneNumber.isEmpty
                    ? nil : phoneNumber
            )
            context.insert(profile)
        }
    }
}
