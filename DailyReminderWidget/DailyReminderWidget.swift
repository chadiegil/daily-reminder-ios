import WidgetKit
import SwiftUI

@main
struct DailyReminderWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyReminderWidget()
    }
}

struct DailyReminderWidget: Widget {
    let kind: String = "DailyReminderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Reminders")
        .description("See today's reminders at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
