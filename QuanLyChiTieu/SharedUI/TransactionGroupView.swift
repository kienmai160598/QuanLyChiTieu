import SwiftUI

// MARK: - Transaction Group View

/// Renders a list of transactions inside a card with dividers.
/// For use in ScrollView contexts (Dashboard, BudgetDetail).
/// For the full transaction list with swipe/delete, use native List directly.
internal struct TransactionGroupView: View {
    internal let transactions: [Transaction]
    internal var zoomNamespace: Namespace.ID?

    internal var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(transactions) { tx in
                transactionCard(tx)
            }
        }
    }

    @ViewBuilder
    private func transactionCard(_ tx: Transaction) -> some View {
        let card = NavigationLink(value: TransactionRoute.detail(tx.persistentModelID)) {
            TransactionRowView(transaction: tx)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .m3Card(cornerRadius: Spacing.cornerHero, background: .surfaceContainerLowest)

        if let ns = zoomNamespace {
            card.matchedTransitionSource(id: tx.persistentModelID, in: ns)
        } else {
            card
        }
    }
}
