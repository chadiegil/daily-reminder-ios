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

// MARK: - Content View (needs ViewModel)

private struct HomeContentView: View {
    @Bindable var viewModel: ReminderListViewModel
    @Binding var showAddSheet: Bool

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $viewModel.selectedTab) {
                ForEach(ReminderTab.allCases, id: \.self) { tab in
                    switch tab {
                    case .today:
                        Text("Today (\(viewModel.todayCount))")
                    case .upcoming:
                        Text("Upcoming (\(viewModel.upcomingCount))")
                    case .overdue:
                        Text("Overdue (\(viewModel.overdueCount))")
                    }
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if viewModel.filteredReminders.isEmpty {
                ContentUnavailableView {
                    Label(emptyTitle, systemImage: emptyIcon)
                } description: {
                    Text(emptyDescription)
                } actions: {
                    Button("Add Reminder") {
                        showAddSheet = true
                    }
                }
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
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search reminders")
        .navigationDestination(for: PersistentIdentifier.self) { id in
            if let reminder = viewModel.reminder(for: id) {
                ReminderDetailView(reminder: reminder, viewModel: viewModel)
            }
        }
    }

    // MARK: - Empty State Helpers

    private var emptyTitle: String {
        switch viewModel.selectedTab {
        case .today: "Nothing Due Today"
        case .upcoming: "No Upcoming Reminders"
        case .overdue: "No Overdue Reminders"
        }
    }

    private var emptyIcon: String {
        switch viewModel.selectedTab {
        case .today: "checkmark.circle"
        case .upcoming: "calendar"
        case .overdue: "clock"
        }
    }

    private var emptyDescription: String {
        switch viewModel.selectedTab {
        case .today: "You're all caught up! Tap below to add a new reminder."
        case .upcoming: "No reminders scheduled for the future."
        case .overdue: "Great job! Nothing is overdue."
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Reminder.self, ReminderHistory.self], inMemory: true)
}
