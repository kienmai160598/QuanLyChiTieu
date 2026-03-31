import Testing
@testable import QuanLyChiTieu

// MARK: - ArcGeometry Tests

@Suite("ArcGeometry.computeAngles")
struct ArcGeometryTests {

    private let gap = ArcGeometry.gapDegrees
    private let cap = ArcGeometry.capOffsetDegrees
    private let tolerance = 0.001

    // MARK: - Edge Cases

    @Test("empty input returns empty array")
    func emptyInput() {
        let result = ArcGeometry.computeAngles(count: 0, values: [])
        #expect(result.isEmpty)
    }

    // MARK: - Single Segment

    @Test("single segment sweep is approximately 360 minus 2*cap")
    func singleSegment() {
        let result = ArcGeometry.computeAngles(count: 1, values: [100])
        #expect(result.count == 1)
        let expected = 360.0 - 2 * cap
        #expect(abs(result[0].sweep - expected) < tolerance)
    }

    // MARK: - Equal Segments

    @Test("two equal segments have equal sweeps")
    func twoEqualSegments() {
        let result = ArcGeometry.computeAngles(count: 2, values: [50, 50])
        #expect(result.count == 2)
        #expect(abs(result[0].sweep - result[1].sweep) < tolerance)
    }

    @Test("N equal segments all have identical sweeps",
          arguments: [3, 5, 8])
    func nEqualSegments(n: Int) {
        let values = Array(repeating: 1.0, count: n)
        let result = ArcGeometry.computeAngles(count: n, values: values)
        #expect(result.count == n)
        let firstSweep = result[0].sweep
        for i in 1..<n {
            #expect(abs(result[i].sweep - firstSweep) < tolerance)
        }
    }

    // MARK: - 360-degree Closure

    @Test("8 segments with varying ratios: slots plus gaps equal 360")
    func eightSegmentsFullCircle() {
        let values = [0.25, 0.15, 0.13, 0.12, 0.10, 0.10, 0.08, 0.07]
        let result = ArcGeometry.computeAngles(count: 8, values: values)
        #expect(result.count == 8)

        // Each drawn arc corresponds to a slot = sweep + 2*cap
        // Total = sum(slots) + count*gap = 360
        let totalSlots = result.map { $0.sweep + 2 * cap }.reduce(0, +)
        let totalGap = Double(8) * gap
        let total = totalSlots + totalGap
        #expect(abs(total - 360.0) < tolerance)
    }

    // MARK: - No Overlap

    @Test("no overlap between adjacent segments")
    func noOverlap() {
        let values = [0.25, 0.15, 0.13, 0.12, 0.10, 0.10, 0.08, 0.07]
        let count = values.count
        let result = ArcGeometry.computeAngles(count: count, values: values)

        for i in 0..<count {
            let j = (i + 1) % count
            let endI = result[i].start + result[i].sweep + cap
            var startJ = result[j].start - cap
            if j == 0 { startJ += 360 }
            #expect(endI <= startJ + tolerance,
                    "Segment \(i) end overlaps segment \(j) start")
        }
    }

    // MARK: - Tiny Segment Minimum

    @Test("tiny segment meets minimum arc, no overlap")
    func tinySegmentMinimum() {
        let values = [0.01, 0.40, 0.30, 0.29]
        let result = ArcGeometry.computeAngles(count: 4, values: values)
        #expect(result.count == 4)

        // Tiny segment drawn sweep must be >= 1 degree
        #expect(result[0].sweep >= 1.0)

        // Verify no overlap
        for i in 0..<4 {
            let j = (i + 1) % 4
            let endI = result[i].start + result[i].sweep + cap
            var startJ = result[j].start - cap
            if j == 0 { startJ += 360 }
            #expect(endI <= startJ + tolerance)
        }
    }

    // MARK: - Sum Check

    @Test("sum of drawn_sweep plus 2*cap plus gap per segment equals 360")
    func perSegmentSumCheck() {
        let values = [3.0, 7.0, 2.0, 5.0, 1.0]
        let count = values.count
        let result = ArcGeometry.computeAngles(count: count, values: values)

        let total = result.map { $0.sweep + 2 * cap + gap }.reduce(0, +)
        #expect(abs(total - 360.0) < tolerance)
    }

    // MARK: - Proportionality

    @Test("larger input value produces larger sweep")
    func proportionality() {
        let values = [10.0, 30.0, 20.0, 40.0]
        let result = ArcGeometry.computeAngles(count: 4, values: values)
        let sorted = values.enumerated().sorted { $0.element < $1.element }
        for k in 0..<(sorted.count - 1) {
            let smallerIdx = sorted[k].offset
            let largerIdx = sorted[k + 1].offset
            #expect(result[smallerIdx].sweep <= result[largerIdx].sweep + tolerance)
        }
    }

    // MARK: - Cursor Closure

    @Test("first segment starts near -90+cap, last ends near 270-gap/2-cap")
    func cursorClosure() {
        let values = [0.25, 0.15, 0.13, 0.12, 0.10, 0.10, 0.08, 0.07]
        let count = values.count
        let result = ArcGeometry.computeAngles(count: count, values: values)

        let expectedFirstStart = -90.0 + cap
        #expect(abs(result[0].start - expectedFirstStart) < tolerance)

        let lastEnd = result[count - 1].start + result[count - 1].sweep
        let expectedLastEnd = 270.0 - gap - cap
        #expect(abs(lastEnd - expectedLastEnd) < tolerance)
    }
}
