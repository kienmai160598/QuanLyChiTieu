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

// MARK: - Schema V3

internal enum SchemaV3: VersionedSchema {
    internal static var versionIdentifier: Schema.Version {
        Schema.Version(3, 0, 0)
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
            SavingsTransaction.self,
            RecurringSavingsDeposit.self,
        ]
    }
}

// MARK: - Current Schema

internal typealias CurrentSchema = SchemaV3

// MARK: - Migration Plan

internal enum AppMigrationPlan: SchemaMigrationPlan {
    internal static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }

    internal static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }

    private static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    private static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )
}
