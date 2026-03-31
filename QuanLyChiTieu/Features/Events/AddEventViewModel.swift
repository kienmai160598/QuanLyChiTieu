import Foundation
import SwiftData

@MainActor @Observable
internal final class AddEventViewModel {

    // MARK: - State

    internal var name: String = ""
    internal var icon: String = "calendar"
    internal var colorHex: String = "#D7A49A"
    internal var startDate: Date = .now
    internal var endDate: Date = Calendar.current.date(
        byAdding: .weekOfYear, value: 1, to: .now
    ) ?? .now
    internal var budgetText: String = ""
    internal var notes: String = ""
    internal var errorMessage: String?

    // MARK: - Icon/Color Choices

    internal static let iconOptions: [String] = [
        "calendar", "airplane", "party.popper.fill",
        "gift.fill", "heart.fill", "star.fill",
        "house.fill", "graduationcap.fill", "figure.walk",
        "trophy.fill", "camera.fill", "music.note",
    ]

    internal static let colorOptions: [String] = [
        "#D7A49A", "#A4B1BA", "#B5B89A", "#E4C9B6", "#E1DAD3", "#3D3633",
    ]

    // MARK: - Computed

    internal var parsedBudget: Decimal? {
        budgetText.parsedVNDAmount
    }

    internal var hasChanges: Bool {
        !name.isEmpty || !budgetText.isEmpty
    }

    internal var canSave: Bool {
        !name.isEmpty && parsedBudget != nil && endDate > startDate
    }

    // MARK: - Actions

    internal func clearError() {
        errorMessage = nil
    }

    internal func save(context: ModelContext) -> Bool {
        guard let budget = validate() else { return false }
        return persistEvent(budget: budget, context: context)
    }

    private func validate() -> Decimal? {
        guard let budget = parsedBudget else {
            errorMessage = String(localized: "Ngân sách phải lớn hơn 0")
            return nil
        }
        guard !name.isEmpty else {
            errorMessage = String(localized: "Vui lòng nhập tên sự kiện")
            return nil
        }
        guard endDate > startDate else {
            errorMessage = String(localized: "Ngày kết thúc phải sau ngày bắt đầu")
            return nil
        }
        return budget
    }

    private func persistEvent(budget: Decimal, context: ModelContext) -> Bool {
        let event = Event(
            name: name, icon: icon, colorHex: colorHex,
            startDate: startDate, endDate: endDate,
            budgetLimit: budget, notes: notes
        )
        context.insert(event)
        do {
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể lưu sự kiện")
            return false
        }
        return true
    }
}
