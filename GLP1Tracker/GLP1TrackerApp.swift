import SwiftUI
import SwiftData

@main
struct GLP1TrackerApp: App {
    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("weekday") private var weekday = 2
    @AppStorage("reminderHour") private var hour = 9
    @AppStorage("reminderMinute") private var minute = 0

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Re-assert the schedule on each launch.
                    await Reminders.update(enabled: reminderOn, weekday: weekday, hour: hour, minute: minute)
                }
        }
        .modelContainer(for: [WeightEntry.self, DoseEntry.self])
    }
}
