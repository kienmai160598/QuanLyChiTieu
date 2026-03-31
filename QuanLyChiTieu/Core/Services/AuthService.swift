import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import OSLog

// MARK: - Auth Service

@MainActor @Observable
internal final class AuthService {
    // MARK: - State

    internal private(set) var isSignedIn: Bool = false
    internal private(set) var isLoading: Bool = false

    // MARK: - Private

    private let keychain: KeychainService
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "QuanLyChiTieu", category: "Auth")
    private var currentNonce: String?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Keychain Keys

    private enum Keys {
        nonisolated static let idToken = "firebase_id_token"
        nonisolated static let uid = "firebase_user_uid"
    }

    // MARK: - Init

    internal init(keychain: KeychainService = KeychainService()) {
        self.keychain = keychain
    }

    internal func startListening() {
        stopListening()
        isSignedIn = Auth.auth().currentUser != nil
        authStateHandle = Auth.auth().addStateDidChangeListener { @Sendable [weak self] _, user in
            let signedIn = user != nil
            Task { @MainActor [weak self] in
                self?.isSignedIn = signedIn
            }
        }
    }

    internal func stopListening() {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateHandle = nil
        }
    }
}

// MARK: - Apple Sign-In

internal extension AuthService {
    func prepareAppleRequest(
        _ request: ASAuthorizationAppleIDRequest
    ) throws {
        let nonce = try Self.randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func signInWithApple(
        _ authorization: ASAuthorization
    ) async throws {
        guard let credential = authorization.credential
                as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
        else {
            throw AuthError.missingCredential
        }

        let oauthCredential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: credential.fullName
        )

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await Auth.auth().signIn(
                with: oauthCredential
            )
            await storeCurrentUserToken()
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
}

// MARK: - Google Sign-In

internal extension AuthService {
    func signInWithGoogle() async throws {
        let rootVC = try resolveRootViewController()
        try configureGoogleSignIn()

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootVC
            )
            try await firebaseSignIn(with: result)
            await storeCurrentUserToken()
        } catch let error as GIDSignInError where error.code == .canceled {
            throw AuthError.signInCancelled
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
}

// MARK: - Google Sign-In Helpers

private extension AuthService {
    func configureGoogleSignIn() throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingCredential
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID
        )
    }

    func resolveRootViewController() throws -> UIViewController {
        guard let scene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController
        else {
            throw AuthError.signInFailed(
                String(localized: "Không tìm thấy cửa sổ ứng dụng.")
            )
        }
        return rootVC
    }

    func firebaseSignIn(with result: GIDSignInResult) async throws {
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingCredential
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        _ = try await Auth.auth().signIn(with: credential)
    }
}

// MARK: - Sign Out

internal extension AuthService {
    func signOut() async throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        await clearTokens()
    }

    func signOutAndClearData(context: ModelContext) async throws {
        try await signOut()
        try context.delete(model: Transaction.self)
        try context.delete(model: Budget.self)
        try context.delete(model: RecurringTransaction.self)
        try context.delete(model: Category.self)
        try context.delete(model: UserProfile.self)
        try context.delete(model: SavingsGoal.self)
        try context.delete(model: Debt.self)
        try context.delete(model: Event.self)
        try context.save()
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "com.quanlychitieu.hasSeededData")
    }
}

// MARK: - User Info

internal extension AuthService {
    var currentUserEmail: String? {
        Auth.auth().currentUser?.email
    }

    var currentUserName: String? {
        Auth.auth().currentUser?.displayName
    }

    var currentUserPhotoURL: URL? {
        Auth.auth().currentUser?.photoURL
    }

    var currentProviderID: String {
        let providers = Auth.auth().currentUser?.providerData ?? []
        if providers.contains(where: { $0.providerID == "apple.com" }) {
            return "apple"
        }
        if providers.contains(where: { $0.providerID == "google.com" }) {
            return "google"
        }
        return "unknown"
    }

    var currentUID: String? {
        Auth.auth().currentUser?.uid
    }
}

// MARK: - Token Management

private extension AuthService {
    func storeCurrentUserToken() async {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid

        let token: String
        do {
            token = try await user.getIDToken()
        } catch {
            logger.error("Failed to retrieve ID token: \(error.localizedDescription, privacy: .public)")
            return
        }

        do {
            try await keychain.saveString(token, for: Keys.idToken)
            try await keychain.saveString(uid, for: Keys.uid)
        } catch {
            logger.error("Failed to save credentials to Keychain: \(error.localizedDescription, privacy: .public)")
        }
    }

    func clearTokens() async {
        try? await keychain.delete(for: Keys.idToken)
        try? await keychain.delete(for: Keys.uid)
    }
}

// MARK: - Crypto Helpers

private extension AuthService {
    nonisolated static func randomNonceString(length: Int = 32) throws -> String {
        guard length > 0 else {
            throw AuthError.signInFailed("Invalid nonce length")
        }
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(
            kSecRandomDefault, bytes.count, &bytes
        )
        guard status == errSecSuccess else {
            throw AuthError.signInFailed("Failed to generate secure nonce")
        }
        let charset: [Character] = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        )
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    nonisolated static func sha256(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
