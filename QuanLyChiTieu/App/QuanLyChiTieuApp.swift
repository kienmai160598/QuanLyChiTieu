import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn
import OSLog

@main
internal struct QuanLyChiTieuApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var languageManager = LanguageManager.shared
    @State private var authService = AuthService()

    private let container: ModelContainer?
    private let containerError: String?

    internal init() {
        FirebaseApp.configure()

        do {
            container = try Self.createContainer()
            containerError = nil
            Self.applyFileProtection()
            #if DEBUG
            SecurityConfiguration.validateATSConfiguration()
            #endif
        } catch {
            // Migration or schema mismatch — delete the corrupt store and retry
            let logger = Logger(
                subsystem: Bundle.main.bundleIdentifier ?? "QuanLyChiTieu",
                category: "DataRecovery"
            )
            logger.error("ModelContainer failed: \(error.localizedDescription, privacy: .public). Attempting recovery…")

            Self.deleteStoreFiles()

            do {
                container = try Self.createContainer()
                containerError = nil
                // Clear seed flag so fresh data is created
                UserDefaults.standard.removeObject(forKey: "com.quanlychitieu.hasSeededData")
                logger.info("Recovery succeeded — database recreated.")
            } catch {
                container = nil
                containerError = error.localizedDescription
            }
        }
    }

    internal var body: some Scene {
        WindowGroup {
            Group {
                if container != nil {
                    AppRootView()
                } else {
                    containerErrorView
                }
            }
            .environment(languageManager)
            .environment(authService)
            .environment(\.locale, languageManager.locale)
            // App switcher protection is applied inside AppRootView
            .tint(Color.appPrimary)
            .preferredColorScheme(isDarkMode ? .dark : nil)
            .task { authService.startListening() }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
        .modelContainer(container ?? Self.makeFallbackContainer())
    }
}

// MARK: - Error Recovery

private extension QuanLyChiTieuApp {
    var containerErrorView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.appError)

            Text("Không thể khởi tạo dữ liệu")
                .font(Typography.headlineMedium)
                .fontWeight(.semibold)

            Text(containerError ?? String(localized: "Lỗi không xác định"))
                .font(Typography.labelMedium)
                .foregroundStyle(Color.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            Text("Vui lòng khởi động lại ứng dụng hoặc liên hệ hỗ trợ.")
                .font(Typography.bodySmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .padding()
    }

    static func makeFallbackContainer() -> ModelContainer {
        let schema = Schema(SchemaV2.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            let minimalSchema = Schema([Transaction.self])
            let minimalConfig = ModelConfiguration(
                isStoredInMemoryOnly: true
            )
            do {
                return try ModelContainer(
                    for: minimalSchema,
                    configurations: [minimalConfig]
                )
            } catch {
                // In-memory container with empty schema as absolute last resort.
                // This path should be unreachable — in-memory containers
                // do not depend on disk I/O and should always succeed.
                do {
                    return try ModelContainer(
                        for: Schema([]),
                        configurations: [ModelConfiguration(
                            isStoredInMemoryOnly: true
                        )]
                    )
                } catch {
                    // Truly unrecoverable: no ModelContainer can be created.
                    // preconditionFailure is acceptable here as the app
                    // cannot function without any data container.
                    preconditionFailure(
                        "Không thể tạo ModelContainer tối thiểu"
                    )
                }
            }
        }
    }

    static func createContainer() throws -> ModelContainer {
        let schema = Schema(SchemaV2.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        return try ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: [config]
        )
    }

    static func deleteStoreFiles() {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return }

        let fm = FileManager.default
        let storeFiles = [
            "default.store",
            "default.store-shm",
            "default.store-wal",
        ]
        for file in storeFiles {
            let url = appSupport.appendingPathComponent(file)
            try? fm.removeItem(at: url)
        }
    }

    static func applyFileProtection() {
        guard let storeURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return }

        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "QuanLyChiTieu", category: "Security")
        do {
            try SecurityConfiguration.applyFileProtection(toStoreAt: storeURL)
        } catch {
            logger.error("applyFileProtection failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
