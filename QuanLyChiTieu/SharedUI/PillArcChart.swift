import SwiftUI

// MARK: - Arc Layout

private enum ArcLayout {
    static let bandWidth: CGFloat = 36
    static let selectedBandWidth: CGFloat = 42
    static let drawInset: CGFloat = 8
    static let badgeSize: CGFloat = 32
    static let badgeIconSize: CGFloat = 14
    static let badgeCorner: CGFloat = 8
    static let selectedScale: CGFloat = 1.04
    static let badgeMinValue: Double = 0.01
}

// MARK: - Pill Arc Chart

internal struct PillArcChart: View {
    private let slices: [PillArcSlice]
    private let angles: [(start: Double, sweep: Double)]
    private let size: CGFloat
    private let centerTitle: String
    private let centerSubtitle: String
    @Binding private var selectedIndex: Int?
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal init(
        slices: [PillArcSlice],
        size: CGFloat = 200,
        centerTitle: String,
        centerSubtitle: String,
        selectedIndex: Binding<Int?> = .constant(nil)
    ) {
        self.slices = slices
        self.angles = ArcGeometry.computeAngles(
            count: slices.count, values: slices.map(\.value)
        )
        self.size = size
        self.centerTitle = centerTitle
        self.centerSubtitle = centerSubtitle
        self._selectedIndex = selectedIndex
    }

    private var frameSize: CGFloat { size + ArcLayout.drawInset * 2 }
    private var outerR: CGFloat { (frameSize / 2) - ArcLayout.drawInset }

    internal var body: some View {
        ZStack {
            segments
            badges
            centerContent
        }
        .frame(width: frameSize, height: frameSize)
        .onAppear {
            if reduceMotion {
                withAnimation(.none) { appeared = true }
            } else {
                appeared = true
            }
        }
    }
}

// MARK: - Segments

private extension PillArcChart {
    var segments: some View {
        ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
            segmentShape(index: index, slice: slice)
        }
    }

    func segmentShape(index: Int, slice: PillArcSlice) -> some View {
        let angle = index < angles.count ? angles[index] : (start: 0.0, sweep: 0.0)
        let isSelected = selectedIndex == index
        let band = isSelected ? ArcLayout.selectedBandWidth : ArcLayout.bandWidth

        return BandArcShape(
            outerR: outerR,
            innerR: outerR - band,
            startDeg: angle.start,
            sweepDeg: appeared ? angle.sweep : 0,
            frameSize: frameSize
        )
        .fill(slice.color)
        .scaleEffect(isSelected ? ArcLayout.selectedScale : 1)
        .animation(reduceMotion ? .none : Motion.spatialFast, value: isSelected)
        .animation(
            reduceMotion ? .none : Motion.spatialSlow.delay(Double(index) * 0.06),
            value: appeared
        )
        .onTapGesture { tapSegment(index) }
        .accessibilityLabel("\(slice.label) \(Int(slice.value * 100))%")
        .accessibilityAddTraits(.isButton)
    }

    func tapSegment(_ index: Int) {
        withAnimation(Motion.spatialDefault) {
            selectedIndex = selectedIndex == index ? nil : index
        }
    }
}

// MARK: - Band Arc Shape (flat ends)

private struct BandArcShape: Shape {
    private let outerR: CGFloat
    private let innerR: CGFloat
    private let startDeg: Double
    private var sweepDeg: Double
    private let frameSize: CGFloat

    internal var animatableData: Double {
        get { sweepDeg }
        set { sweepDeg = newValue }
    }

    internal init(
        outerR: CGFloat, innerR: CGFloat,
        startDeg: Double, sweepDeg: Double, frameSize: CGFloat
    ) {
        self.outerR = outerR
        self.innerR = innerR
        self.startDeg = startDeg
        self.sweepDeg = sweepDeg
        self.frameSize = frameSize
    }

    internal func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let cr: CGFloat = 8
        let s = startDeg * .pi / 180
        let e = (startDeg + sweepDeg) * .pi / 180
        let oδ = atan2(Double(cr), Double(outerR))
        let iδ = atan2(Double(cr), Double(innerR))

        func pt(_ r: CGFloat, _ a: Double) -> CGPoint {
            CGPoint(x: center.x + r * CGFloat(cos(a)),
                    y: center.y + r * CGFloat(sin(a)))
        }

        var p = Path()
        p.move(to: pt(outerR, s + oδ))
        p.addArc(center: center, radius: outerR,
                 startAngle: .radians(s + oδ), endAngle: .radians(e - oδ),
                 clockwise: false)
        p.addArc(tangent1End: pt(outerR, e), tangent2End: pt(innerR, e), radius: cr)
        p.addArc(tangent1End: pt(innerR, e), tangent2End: pt(innerR, e - iδ), radius: cr)
        p.addArc(center: center, radius: innerR,
                 startAngle: .radians(e - iδ), endAngle: .radians(s + iδ),
                 clockwise: true)
        p.addArc(tangent1End: pt(innerR, s), tangent2End: pt(outerR, s), radius: cr)
        p.addArc(tangent1End: pt(outerR, s), tangent2End: pt(outerR, s + oδ), radius: cr)
        p.closeSubpath()
        return p
    }
}

// MARK: - Icon Badges (floating outside the ring)

private extension PillArcChart {
    var badges: some View {
        ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
            badgeView(index: index, slice: slice)
        }
    }

    func badgeView(index: Int, slice: PillArcSlice) -> some View {
        let angle = index < angles.count ? angles[index] : (start: 0.0, sweep: 0.0)
        let midR = outerR - ArcLayout.bandWidth / 2
        let mid = (angle.start + angle.sweep / 2) * .pi / 180
        let x = midR * cos(mid)
        let y = midR * sin(mid)

        return Image(systemName: slice.icon)
            .font(.system(size: ArcLayout.badgeIconSize, weight: .semibold))
            .foregroundStyle(Color.onPrimary)
            .scaleEffect(appeared ? 1 : 0.01)
            .offset(x: x, y: y)
            .animation(
                reduceMotion ? .none : Motion.spatialDefault.delay(appeared ? Double(index) * 0.06 + 0.1 : 0),
                value: appeared
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Center Label

private extension PillArcChart {
    var centerContent: some View {
        VStack(spacing: Spacing.xs) {
            Text(centerTitle)
                .font(Typography.heroLarge)
                .monospacedDigit()
                .foregroundStyle(Color.onSurface)
                .minimumScaleFactor(0.4)
                .lineLimit(1)

            Text(centerSubtitle)
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)

            selectedDetail
        }
        .frame(width: size * 0.45)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    var selectedDetail: some View {
        if let index = selectedIndex, index < slices.count {
            let slice = slices[index]
            let pct = Int(slice.value * 100)
            VStack(spacing: Spacing.xxs) {
                Text(slice.label)
                    .font(Typography.labelMedium)
                    .foregroundStyle(slice.color)
                Text("\(pct)%")
                    .font(Typography.titleSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(slice.color)
            }
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }
}

// MARK: - Preview

#Preview {
    PillArcChart(
        slices: [
            PillArcSlice(id: "1", label: "Ăn uống", icon: "fork.knife", value: 0.25, color: Color(hex: "#D7A49A")),
            PillArcSlice(id: "2", label: "Di chuyển", icon: "car.fill", value: 0.20, color: Color(hex: "#A4B1BA")),
            PillArcSlice(id: "3", label: "Mua sắm", icon: "bag.fill", value: 0.18, color: Color(hex: "#B5B89A")),
            PillArcSlice(id: "4", label: "Giải trí", icon: "gamecontroller.fill", value: 0.15, color: Color(hex: "#E4C9B6")),
            PillArcSlice(id: "5", label: "Hoá đơn", icon: "doc.text.fill", value: 0.12, color: Color(hex: "#C4877D")),
            PillArcSlice(id: "6", label: "Sức khoẻ", icon: "heart.fill", value: 0.10, color: Color(hex: "#8A9A72")),
        ],
        size: 280,
        centerTitle: "1,1tr",
        centerSubtitle: "chi tiêu"
    )
    .padding()
}
