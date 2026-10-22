import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
    @Query(sort: \DoseEntry.date) private var doses: [DoseEntry]

    @AppStorage("unit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("weekday") private var weekday = 2
    @AppStorage("reminderHour") private var hour = 9
    @AppStorage("reminderMinute") private var minute = 0

    @State private var exportURL: URL?
    @State private var confirmDelete = false

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now
            },
            set: { newValue in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                hour = parts.hour ?? 9
                minute = parts.minute ?? 0
            }
        )
    }

    private var scheduleKey: String { "\(reminderOn)-\(weekday)-\(hour)-\(minute)" }

    var body: some View {
        Form {
            Section("Weight units") {
                Picker("Show weights in", selection: $unitRaw) {
                    ForEach(WeightUnit.allCases) { Text($0.label).tag($0.rawValue) }
                }
            }

            Section {
                Toggle("Weekly reminder", isOn: $reminderOn)
                if reminderOn {
                    Picker("Injection day", selection: $weekday) {
                        ForEach(1...7, id: \.self) { day in
                            Text(Calendar.current.weekdaySymbols[day - 1]).tag(day)
                        }
                    }
                    DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Reminder")
            } footer: {
                Text("The notification just says it's injection day. It never names your medication.")
            }

            Section("Your data") {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Export as CSV", systemImage: "square.and.arrow.up")
                    }
                }
                Button("Delete all data", role: .destructive) { confirmDelete = true }
            }

            Section("About") {
                Text("Everything stays on this iPhone. No account, no analytics, no network access. This app only records what you enter and gives no medical advice.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshExport)
        .onChange(of: weights.count) { _, _ in refreshExport() }
        .onChange(of: doses.count) { _, _ in refreshExport() }
        .onChange(of: scheduleKey) { _, _ in
            Task { await Reminders.update(enabled: reminderOn, weekday: weekday, hour: hour, minute: minute) }
        }
        .confirmationDialog("Delete all weights and doses?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) {
                for entry in weights { context.delete(entry) }
                for dose in doses { context.delete(dose) }
            }
        } message: {
            Text("Export a CSV first if you want a backup. This can't be undone.")
        }
    }

    private func refreshExport() {
        exportURL = CSVExport.write(weights: weights, doses: doses)
    }
}

enum CSVExport {
    static func write(weights: [WeightEntry], doses: [DoseEntry]) -> URL? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]

        var lines = ["type,date,weight_kg,medication,dose_mg,site"]
        for entry in weights {
            lines.append("weight,\(iso.string(from: entry.date)),\(String(format: "%.2f", entry.kg)),,,")
        }
        for dose in doses {
            let name = dose.medication.replacingOccurrences(of: ",", with: " ")
            let site = dose.site.replacingOccurrences(of: ",", with: " -")
            lines.append("dose,\(iso.string(from: dose.date)),,\(name),\(dose.doseMg),\(site)")
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dose-and-weight.csv")
        do {
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
