import SwiftData

// MARK: - Schema V1

internal enum SchemaV1: VersionedSchema {
    internal static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    internal static var models: [any PersistentModel.Type] {
        [
            Transaction.self,
            Category.self,
            Budget.self,
            RecurringTransaction.self,
            UserProfile.self,
        ]
    }
}

// MARK: - Schema V2

internal enum SchemaV2: VersionedSchema {
    internal static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
    }

    internal static var models: [any PersistentModel.Type] {
        [
            Transaction.self,
            Category.self,
            Budget.self,
            RecurringTransaction.self,
            UserProfile.self,
            SavingsGoal.self,
            Debt.self,
            Event.self,
        ]
    }
}

// MARK: - Migration Plan

internal enum AppMigrationPlan: SchemaMigrationPlan {
    internal static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    internal static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    private static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
