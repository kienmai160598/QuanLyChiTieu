import Foundation
import SwiftData

// MARK: - Gender

internal enum Gender: String, Codable, CaseIterable, Sendable {
    case male = "male"
    case female = "female"
    case other = "other"

    internal var displayName: String {
        switch self {
        case .male: String(localized: "Nam")
        case .female: String(localized: "Nữ")
        case .other: String(localized: "Khác")
        }
    }
}

// MARK: - User Profile Model

@Model
internal final class UserProfile {
    internal var uid: String
    internal var displayName: String?
    internal var email: String?
    internal var photoURL: String?
    internal var provider: String
    internal var gender: String?
    internal var birthday: Date?
    internal var phoneNumber: String?
    internal var createdAt: Date
    internal var lastSignInAt: Date

    internal init(
        uid: String,
        displayName: String? = nil,
        email: String? = nil,
        photoURL: String? = nil,
        provider: String,
        gender: String? = nil,
        birthday: Date? = nil,
        phoneNumber: String? = nil,
        createdAt: Date = Date(),
        lastSignInAt: Date = Date()
    ) {
        self.uid = uid
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.provider = provider
        self.gender = gender
        self.birthday = birthday
        self.phoneNumber = phoneNumber
        self.createdAt = createdAt
        self.lastSignInAt = lastSignInAt
    }

    internal var genderEnum: Gender? {
        get { gender.flatMap { Gender(rawValue: $0) } }
        set { gender = newValue?.rawValue }
    }
}
