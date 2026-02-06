import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ReminderListViewModel?
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    HomeContentView(viewModel: viewModel, showAddSheet: $showAddSheet)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                if let viewModel {
                    AddReminderView(viewModel: viewModel)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ReminderListViewModel(modelContext: modelContext)
                }
            }
        }
    }
}

// MARK: - Glassmorphic Tab Bar

private struct GlassTabBar: View {
    @Binding var selectedTab: ReminderTab
    let todayCount: Int
    let upcomingCount: Int
    let overdueCount: Int
    let monthCount: Int
    @Namespace private var tabAnimation

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ReminderTab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.85)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: iconFor(tab))
                            .font(.system(size: 12, weight: .semibold))
                            .symbolEffect(.bounce, value: isSelected)

                        Text(labelFor(tab))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))

                        Text("\(countFor(tab))")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? .white.opacity(0.25) : .primary.opacity(0.08))
                            )
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: gradientFor(tab),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: shadowColorFor(tab), radius: 8, y: 2)
                                .matchedGeometryEffect(id: "activeTab", in: tabAnimation)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .white.opacity(0.05),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func iconFor(_ tab: ReminderTab) -> String {
        switch tab {
        case .today: "sun.max.fill"
        case .upcoming: "calendar.badge.clock"
        case .overdue: "exclamationmark.triangle.fill"
        case .month: "calendar"
        }
    }

    private func labelFor(_ tab: ReminderTab) -> String {
        switch tab {
        case .today: "Today"
        case .upcoming: "Soon"
        case .overdue: "Late"
        case .month: "Month"
        }
    }

    private func countFor(_ tab: ReminderTab) -> Int {
        switch tab {
        case .today: todayCount
        case .upcoming: upcomingCount
        case .overdue: overdueCount
        case .month: monthCount
        }
    }

    private func gradientFor(_ tab: ReminderTab) -> [Color] {
        switch tab {
        case .today: [
            Color(red: 0.25, green: 0.50, blue: 0.95),
            Color(red: 0.35, green: 0.40, blue: 0.90)
        ]
        case .upcoming: [
            Color(red: 0.40, green: 0.30, blue: 0.85),
            Color(red: 0.50, green: 0.25, blue: 0.80)
        ]
        case .overdue: [
            Color(red: 0.90, green: 0.35, blue: 0.30),
            Color(red: 0.85, green: 0.25, blue: 0.40)
        ]
        case .month: [
            Color(red: 0.15, green: 0.65, blue: 0.60),
            Color(red: 0.20, green: 0.55, blue: 0.70)
        ]
        }
    }

    private func shadowColorFor(_ tab: ReminderTab) -> Color {
        switch tab {
        case .today: .blue.opacity(0.3)
        case .upcoming: .purple.opacity(0.3)
        case .overdue: .red.opacity(0.3)
        case .month: .teal.opacity(0.3)
        }
    }
}

// MARK: - Content View (needs ViewModel)

private struct HomeContentView: View {
    @Bindable var viewModel: ReminderListViewModel
    @Binding var showAddSheet: Bool

    var body: some View {
        VStack(spacing: 0) {
            GlassTabBar(
                selectedTab: $viewModel.selectedTab,
                todayCount: viewModel.todayCount,
                upcomingCount: viewModel.upcomingCount,
                overdueCount: viewModel.overdueCount,
                monthCount: viewModel.monthCount
            )

            Group {
                if viewModel.selectedTab == .month {
                    MonthlyCalendarView(viewModel: viewModel)
                } else if viewModel.filteredReminders.isEmpty {
                    ContentUnavailableView {
                        Label(emptyTitle, systemImage: emptyIcon)
                    } description: {
                        Text(emptyDescription)
                    } actions: {
                        Button("Add Reminder") {
                            showAddSheet = true
                        }
                    }
                    .transition(.opacity)
                } else {
                    List(viewModel.filteredReminders) { reminder in
                        NavigationLink(value: reminder.persistentModelID) {
                            ReminderRowView(
                                reminder: reminder,
                                onDone: { viewModel.markAsDone(reminder) },
                                onSkip: { viewModel.markAsSkipped(reminder) }
                            )
                        }
                    }
                    .listStyle(.plain)
                    .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.15), value: viewModel.selectedTab)
        }
        .searchable(text: $viewModel.searchText, prompt: "Search reminders")
        .navigationDestination(for: PersistentIdentifier.self) { id in
            if let reminder = viewModel.reminder(for: id) {
                ReminderDetailView(reminder: reminder, viewModel: viewModel)
            }
        }
        .navigationDestination(for: Date.self) { date in
            DayDetailView(date: date, viewModel: viewModel)
        }
    }

    // MARK: - Empty State Helpers

    private var emptyTitle: String {
        switch viewModel.selectedTab {
        case .today: "Nothing Due Today"
        case .upcoming: "No Upcoming Reminders"
        case .overdue: "No Overdue Reminders"
        case .month: ""
        }
    }

    private var emptyIcon: String {
        switch viewModel.selectedTab {
        case .today: "checkmark.circle"
        case .upcoming: "calendar"
        case .overdue: "clock"
        case .month: "calendar"
        }
    }

    private var emptyDescription: String {
        switch viewModel.selectedTab {
        case .today: "You're all caught up! Tap below to add a new reminder."
        case .upcoming: "No reminders scheduled for the future."
        case .overdue: "Great job! Nothing is overdue."
        case .month: ""
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Reminder.self, ReminderHistory.self], inMemory: true)
}
