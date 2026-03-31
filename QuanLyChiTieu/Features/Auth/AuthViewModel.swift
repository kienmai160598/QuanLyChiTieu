import SwiftUI
import SwiftData
import AuthenticationServices

// MARK: - Auth ViewModel

@MainActor @Observable
internal final class AuthViewModel {
    // MARK: - State

    internal private(set) var isLoading: Bool = false
    internal var errorMessage: String?
    internal var isShowingError: Bool = false

    // MARK: - Dependencies

    private let authService: AuthService

    // MARK: - Init

    internal init(authService: AuthService) {
        self.authService = authService
    }
}

// MARK: - Apple Sign-In

internal extension AuthViewModel {
    func configureAppleRequest(
        _ request: ASAuthorizationAppleIDRequest
    ) {
        do {
            try authService.prepareAppleRequest(request)
        } catch {
            showError(error)
        }
    }

    func handleAppleSignIn(
        _ result: Result<ASAuthorization, Error>,
        context: ModelContext
    ) async {
        switch result {
        case .success(let authorization):
            do {
                isLoading = true
                defer { isLoading = false }
                try await authService.signInWithApple(authorization)
                saveUserProfile(context: context)
            } catch AuthError.signInCancelled {
                // Intentional cancel — no error
            } catch {
                showError(error)
            }
        case .failure(let error):
            let code = (error as NSError).code
            if code != ASAuthorizationError.canceled.rawValue {
                showError(error)
            }
        }
    }
}

// MARK: - Google Sign-In

internal extension AuthViewModel {
    func handleGoogleSignIn(context: ModelContext) async {
        do {
            isLoading = true
            defer { isLoading = false }
            try await authService.signInWithGoogle()
            saveUserProfile(context: context)
        } catch AuthError.signInCancelled {
            // Intentional cancel — no error
        } catch {
            showError(error)
        }
    }
}

// MARK: - Helpers

private extension AuthViewModel {
    func saveUserProfile(context: ModelContext) {
        guard let uid = authService.currentUID else { return }
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = (try? context.fetch(descriptor))?.first
        upsertProfile(uid: uid, existing: existing, context: context)
        persistProfile(context: context)
        cacheUserName()
    }

    func upsertProfile(
        uid: String,
        existing: UserProfile?,
        context: ModelContext
    ) {
        if let profile = existing {
            updateExistingProfile(profile)
        } else {
            let profile = UserProfile(
                uid: uid,
                displayName: authService.currentUserName,
                email: authService.currentUserEmail,
                photoURL: authService.currentUserPhotoURL?.absoluteString,
                provider: authService.currentProviderID
            )
            context.insert(profile)
        }
    }

    func updateExistingProfile(_ profile: UserProfile) {
        profile.lastSignInAt = Date()
        profile.provider = authService.currentProviderID
        if let name = authService.currentUserName { profile.displayName = name }
        if let email = authService.currentUserEmail { profile.email = email }
        if let photo = authService.currentUserPhotoURL {
            profile.photoURL = photo.absoluteString
        }
    }

    func persistProfile(context: ModelContext) {
        do {
            try context.save()
        } catch {
            showError(error)
        }
    }

    func cacheUserName() {
        // Store name in UserDefaults for backward compatibility
        if let name = authService.currentUserName {
            UserDefaults.standard.set(name, forKey: "userName")
        }
    }

    func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        isShowingError = true
    }
}
