import SwiftUI

// MARK: - Arc Geometry

internal enum ArcGeometry {
    internal static let gapDegrees: Double = 2
    internal static let capOffsetDegrees: Double = 0

    internal static func midAngles(
        for slices: [PillArcSlice]
    ) -> [(Int, Double)] {
        let angles = computeAngles(count: slices.count, values: slices.map(\.value))
        return angles.enumerated().map { i, entry in
            (i, entry.start + entry.sweep / 2)
        }
    }

    internal static func computeAngles(
        count: Int,
        values: [Double]
    ) -> [(start: Double, sweep: Double)] {
        guard count > 0 else { return [] }

        let ratios = normalizeRatios(values, count: count)
        var slots = computeSlots(ratios: ratios, count: count)
        enforceMinimumSlots(&slots, count: count)
        return layoutArcs(slots: slots, count: count)
    }

    // MARK: - Private Helpers

    private static func normalizeRatios(
        _ values: [Double],
        count: Int
    ) -> [Double] {
        let sum = values.reduce(0, +)
        if sum > 0 {
            return values.map { $0 / sum }
        }
        return Array(repeating: 1.0 / Double(count), count: count)
    }

    private static func computeSlots(
        ratios: [Double],
        count: Int
    ) -> [Double] {
        let gap = count >= 2 ? gapDegrees : 0.0
        let totalGap = Double(count) * gap
        let available = 360.0 - totalGap
        return ratios.map { available * $0 }
    }

    private static let minimumSlot: Double = 16

    private static func enforceMinimumSlots(
        _ slots: inout [Double],
        count: Int
    ) {
        guard count >= 2 else { return }

        var deficit = 0.0
        for i in 0..<count where slots[i] < minimumSlot {
            deficit += minimumSlot - slots[i]
            slots[i] = minimumSlot
        }
        guard deficit > 0 else { return }

        let largeSum = slots
            .filter { $0 > minimumSlot }
            .reduce(0, +)
        guard largeSum > 0 else { return }

        for i in 0..<count where slots[i] > minimumSlot {
            slots[i] -= deficit * (slots[i] / largeSum)
        }

        // Last segment absorbs floating-point remainder
        let gap = gapDegrees
        let totalGap = Double(count) * gap
        let available = 360.0 - totalGap
        let currentSum = slots.dropLast().reduce(0, +)
        slots[count - 1] = available - currentSum
    }

    private static func layoutArcs(
        slots: [Double],
        count: Int
    ) -> [(start: Double, sweep: Double)] {
        let gap = count >= 2 ? gapDegrees : 0.0
        var cursor = -90.0
        var result: [(start: Double, sweep: Double)] = []
        result.reserveCapacity(count)

        for i in 0..<count {
            result.append((cursor, slots[i]))
            cursor += slots[i] + gap
        }
        return result
    }
}
