import Foundation

// MARK: - Tax Bracket

internal struct TaxBracket: Identifiable, Sendable {
    internal let id: Int
    internal let lowerBound: Decimal
    internal let upperBound: Decimal?
    internal let rate: Decimal
    internal var taxableAmount: Decimal = 0
    internal var taxAmount: Decimal = 0

    internal var ratePercent: Int {
        NSDecimalNumber(decimal: rate * 100).intValue
    }

    internal var label: String {
        guard let upper = upperBound else {
            return String(localized: "Trên \(lowerBound.formattedVND)")
        }
        return "\(lowerBound.formattedVND) - \(upper.formattedVND)"
    }
}

// MARK: - ViewModel

@MainActor @Observable
internal final class PITCalculatorViewModel {
    internal var grossSalary: String = ""
    internal var numberOfDependents: Int = 0
    internal var socialInsuranceRate: Decimal = 0.105

    private static let personalDeduction: Decimal = 11_000_000
    private static let dependentDeduction: Decimal = 4_400_000

    private static let bracketDefinitions: [(lower: Decimal, upper: Decimal?, rate: Decimal)] = [
        (0, 5_000_000, 0.05),
        (5_000_000, 10_000_000, 0.10),
        (10_000_000, 18_000_000, 0.15),
        (18_000_000, 32_000_000, 0.20),
        (32_000_000, 52_000_000, 0.25),
        (52_000_000, 80_000_000, 0.30),
        (80_000_000, nil, 0.35),
    ]

    // MARK: - Computed Properties

    internal var parsedGross: Decimal {
        let cleaned = grossSalary.replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Decimal(string: cleaned) ?? 0
    }

    internal var socialInsuranceAmount: Decimal {
        parsedGross * socialInsuranceRate
    }

    internal var totalDeduction: Decimal {
        socialInsuranceAmount + personalDeductionAmount + dependentDeductionAmount
    }

    internal var personalDeductionAmount: Decimal {
        Self.personalDeduction
    }

    internal var dependentDeductionAmount: Decimal {
        Self.dependentDeduction * Decimal(numberOfDependents)
    }

    internal var taxableIncome: Decimal {
        max(0, parsedGross - totalDeduction)
    }

    internal var taxAmount: Decimal {
        calculateBrackets().reduce(Decimal.zero) { $0 + $1.taxAmount }
    }

    internal var effectiveRate: Double {
        guard parsedGross > 0 else { return 0 }
        let rate = taxAmount / parsedGross * 100
        return NSDecimalNumber(decimal: rate).doubleValue
    }

    internal var netSalary: Decimal {
        parsedGross - socialInsuranceAmount - taxAmount
    }

    // MARK: - Bracket Breakdown

    internal func calculateBrackets() -> [TaxBracket] {
        let income = taxableIncome
        guard income > 0 else {
            return Self.bracketDefinitions.enumerated().map { index, def in
                TaxBracket(
                    id: index, lowerBound: def.lower,
                    upperBound: def.upper, rate: def.rate
                )
            }
        }
        return Self.bracketDefinitions.enumerated().map { index, def in
            buildBracket(index: index, definition: def, income: income)
        }
    }

    internal var socialInsuranceRatePercent: String {
        let value = NSDecimalNumber(decimal: socialInsuranceRate * 100).doubleValue
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Private Helpers

private extension PITCalculatorViewModel {
    private func buildBracket(
        index: Int,
        definition: (lower: Decimal, upper: Decimal?, rate: Decimal),
        income: Decimal
    ) -> TaxBracket {
        let lower = definition.lower
        let upper = definition.upper
        let rate = definition.rate

        let bracketWidth = bracketTaxableAmount(
            income: income, lower: lower, upper: upper
        )
        return TaxBracket(
            id: index, lowerBound: lower,
            upperBound: upper, rate: rate,
            taxableAmount: bracketWidth,
            taxAmount: bracketWidth * rate
        )
    }

    private func bracketTaxableAmount(
        income: Decimal, lower: Decimal, upper: Decimal?
    ) -> Decimal {
        guard income > lower else { return 0 }
        if let upper {
            return min(income, upper) - lower
        }
        return income - lower
    }
}
