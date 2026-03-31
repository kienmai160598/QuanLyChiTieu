import SwiftUI
import SwiftData

internal struct EventListView: View {
    @Query(sort: \Event.startDate, order: .reverse)
    private var allEvents: [Event]

    @Environment(\.modelContext) private var context
    @State private var showAddSheet = false
    @State private var eventToDelete: Event?
    @State private var deleteError: String?

    private var activeEvents: [Event] {
        allEvents.filter { $0.isActive }
    }

    private var upcomingEvents: [Event] {
        allEvents.filter { $0.startDate > Date.now }
    }

    private var pastEvents: [Event] {
        allEvents.filter { $0.endDate < Date.now }
    }

    internal var body: some View {
        Group {
            if allEvents.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .appBackground()
        .navigationTitle(String(localized: "Sự kiện"))
        .toolbar { addToolbar }
        .sheet(isPresented: $showAddSheet) {
            AddEventSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
                .presentationBackground(Color.surfaceContainerLowest)
        }
        .confirmationDialog(
            String(localized: "Xoá sự kiện"),
            isPresented: Binding(
                get: { eventToDelete != nil },
                set: { if !$0 { eventToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "Xoá"), role: .destructive) {
                if let event = eventToDelete { deleteEvent(event) }
            }
            Button(String(localized: "Huỷ"), role: .cancel) { eventToDelete = nil }
        } message: {
            Text(String(localized: "Bạn có chắc muốn xoá sự kiện này?"))
        }
        .alert(String(localized: "Lỗi"), isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button(String(localized: "OK")) {}
        } message: {
            Text(deleteError ?? "")
        }
    }
}

// MARK: - List Content

private extension EventListView {
    private var listContent: some View {
        List {
            if !activeEvents.isEmpty {
                eventSection(
                    title: String(localized: "Đang diễn ra"),
                    events: activeEvents
                )
            }
            if !upcomingEvents.isEmpty {
                eventSection(
                    title: String(localized: "Sắp tới"),
                    events: upcomingEvents
                )
            }
            if !pastEvents.isEmpty {
                eventSection(
                    title: String(localized: "Đã kết thúc"),
                    events: pastEvents
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(Motion.effectDefault, value: allEvents.count)
    }

    private func eventSection(title: String, events: [Event]) -> some View {
        Section {
            ForEach(events) { event in
                NavigationLink(value: EventRoute.detail(event.persistentModelID)) {
                    eventRow(event)
                }
                .m3SectionRow()
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        eventToDelete = event
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        } header: {
            sectionHeader(title: title, count: events.count)
        }
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .textCase(nil)
            Spacer()
            Text(String(localized: "\(count) sự kiện"))
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .textCase(nil)
        }
    }
}

// MARK: - Event Row

private extension EventListView {
    private func eventRow(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            eventRowHeader(event)
            CapsuleProgressBar(
                progress: event.budgetProgress,
                tint: progressColor(for: event)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(event.name)
        .accessibilityValue(event.formattedBudget)
    }

    private func eventRowHeader(_ event: Event) -> some View {
        HStack(spacing: Spacing.md) {
            M3IconBadge(
                icon: event.icon,
                color: Color(hex: event.colorHex)
            )
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(event.name)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(1)
                Text(dateRangeLabel(event))
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(event.spentAmount.formattedVND)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Color.onSurface)
                    .monospacedDigit()
                Text("/ \(event.formattedBudget)")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
    }
}

// MARK: - Empty State

private extension EventListView {
    private var emptyState: some View {
        ScrollView {
            EmptyStateCard(
                icon: "calendar.badge.plus",
                title: String(localized: "Chưa có sự kiện"),
                actionLabel: String(localized: "Thêm sự kiện"),
                onAction: { showAddSheet = true }
            )
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xxxl)
        }
    }
}

// MARK: - Toolbar

private extension EventListView {
    @ToolbarContentBuilder
    private var addToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel(String(localized: "Thêm sự kiện"))
        }
    }
}

// MARK: - Actions & Helpers

private extension EventListView {
    private func deleteEvent(_ event: Event) {
        context.delete(event)
        do {
            try context.save()
        } catch {
            deleteError = error.localizedDescription
        }
    }

    private func dateRangeLabel(_ event: Event) -> String {
        let start = event.startDate.formatted(.dateTime.day().month(.abbreviated))
        let end = event.endDate.formatted(.dateTime.day().month(.abbreviated))
        return "\(start) — \(end)"
    }

    private func progressColor(for event: Event) -> Color {
        let progress = event.budgetProgress
        if progress >= 0.9 { return Color.appError }
        if progress >= 0.7 { return Color.appWarning }
        return Color(hex: event.colorHex)
    }
}

#Preview {
    NavigationStack { EventListView() }
        .modelContainer(for: Event.self, inMemory: true)
}
