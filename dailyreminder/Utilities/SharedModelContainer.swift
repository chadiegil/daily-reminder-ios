import Foundation
import SwiftData

enum SharedModelContainer {
    static var container: ModelContainer = {
        let schema = Schema([Reminder.self, ReminderHistory.self])
        let config = ModelConfiguration(schema: schema)
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}
