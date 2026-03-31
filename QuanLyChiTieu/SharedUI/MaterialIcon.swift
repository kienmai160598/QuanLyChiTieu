import SwiftUI

// MARK: - Material Icon View

/// Renders a Material Symbols Rounded icon using the subset font.
internal struct MaterialIcon: View {
    private let icon: Icon
    private let size: CGFloat

    internal init(_ icon: Icon, size: CGFloat = 24) {
        self.icon = icon
        self.size = size
    }

    internal var body: some View {
        Text(icon.character)
            .font(.custom(Self.fontName, size: size))
    }

    private static let fontName = "Material Symbols Rounded"
}

// MARK: - Icon Catalog

extension MaterialIcon {
    internal enum Icon: String {
        // Navigation
        case home
        case gridView
        case arrowBack
        case arrowForward
        case chevronLeft
        case chevronRight
        case expandMore
        case expandLess
        case close
        case cancel
        case menu

        // Actions
        case add
        case addCircle
        case edit
        case delete
        case share
        case contentCopy
        case undo
        case check
        case checkCircle
        case filterList
        case search

        // Finance
        case wallet
        case payments
        case sell
        case pieChart
        case barChart
        case analytics
        case trendingUp

        // Arrows
        case arrowUpward
        case arrowDownward
        case northEast
        case southWest

        // People
        case person
        case personAdd
        case group

        // Time & Calendar
        case calendarToday
        case event
        case schedule

        // Files
        case description
        case article
        case stickyNote

        // Settings & Security
        case settings
        case lock
        case lockClock
        case security
        case face
        case fingerprint
        case logout

        // Status
        case notifications
        case warning
        case help
        case radioUnchecked

        // Misc
        case darkMode
        case language
        case autorenew
        case sync
        case eco
        case autoAwesome
        case addPhoto
        case label

        internal var codepoint: UInt32 {
            switch self {
            case .home: 0xe88a
            case .gridView: 0xe9b0
            case .arrowBack: 0xe5c4
            case .arrowForward: 0xe5c8
            case .chevronLeft: 0xe5cb
            case .chevronRight: 0xe5cc
            case .expandMore: 0xe5cf
            case .expandLess: 0xe5ce
            case .close: 0xe5cd
            case .cancel: 0xe5c9
            case .menu: 0xe5d2
            case .add: 0xe145
            case .addCircle: 0xe147
            case .edit: 0xe3c9
            case .delete: 0xe872
            case .share: 0xe80d
            case .contentCopy: 0xe14d
            case .undo: 0xe166
            case .check: 0xe5ca
            case .checkCircle: 0xe86c
            case .filterList: 0xe152
            case .search: 0xe8b1
            case .wallet: 0xe850
            case .payments: 0xef63
            case .sell: 0xf05b
            case .pieChart: 0xe6c4
            case .barChart: 0xe26b
            case .analytics: 0xef3e
            case .trendingUp: 0xe8e5
            case .arrowUpward: 0xe5d8
            case .arrowDownward: 0xe5db
            case .northEast: 0xf1e1
            case .southWest: 0xf1e3
            case .person: 0xe7fd
            case .personAdd: 0xe7fe
            case .group: 0xe7ef
            case .calendarToday: 0xe935
            case .event: 0xe878
            case .schedule: 0xe8b5
            case .description: 0xe873
            case .article: 0xef42
            case .stickyNote: 0xf1fc
            case .settings: 0xe8b8
            case .lock: 0xe897
            case .lockClock: 0xef57
            case .security: 0xe32a
            case .face: 0xe87c
            case .fingerprint: 0xe90d
            case .logout: 0xe9ba
            case .notifications: 0xe7f4
            case .warning: 0xe002
            case .help: 0xe887
            case .radioUnchecked: 0xe836
            case .darkMode: 0xe51c
            case .language: 0xe894
            case .autorenew: 0xe863
            case .sync: 0xe627
            case .eco: 0xea35
            case .autoAwesome: 0xe65f
            case .addPhoto: 0xe43e
            case .label: 0xe892
            }
        }

        internal var character: String {
            guard let scalar = Unicode.Scalar(codepoint) else { return "?" }
            return String(scalar)
        }
    }
}
