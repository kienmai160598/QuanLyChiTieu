import Foundation

// MARK: - SavingsCategory

internal enum SavingsCategory: String, Codable, CaseIterable, Sendable {
    case shortTerm = "short_term"
    case longTerm = "long_term"
    case emergency = "emergency"
    case travel = "travel"
    case education = "education"
    case other = "other"

    internal var displayName: String {
        switch self {
        case .shortTerm: String(localized: "Ngắn hạn")
        case .longTerm: String(localized: "Dài hạn")
        case .emergency: String(localized: "Quỹ khẩn cấp")
        case .travel: String(localized: "Du lịch")
        case .education: String(localized: "Giáo dục")
        case .other: String(localized: "Khác")
        }
    }

    internal var icon: String {
        switch self {
        case .shortTerm: "clock"
        case .longTerm: "calendar"
        case .emergency: "cross.case"
        case .travel: "airplane"
        case .education: "graduationcap"
        case .other: "folder"
        }
    }
}
