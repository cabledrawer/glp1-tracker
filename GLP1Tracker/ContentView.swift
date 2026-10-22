import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
    @Query(sort: \DoseEntry.date) private var doses: [DoseEntry]

    @AppStorage("unit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("weekday") private var weekday = 2

    @State private var range: ChartRange = .sixMonths
    @State private var showWeightSheet = false
    @State private var showDoseSheet = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    chartCard
                    nextDoseCard
                    HStack(spacing: 12) {
                        Button { showWeightSheet = true } label: {
                            Label("Log weight", systemImage: "scalemass")
                                .frame(maxWidth: .infinity)
                        }
                        Button { showDoseSheet = true } label: {
                            Label("Log dose", systemImage: "syringe")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dose & Weight")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { HistoryView() } label: { Image(systemName: "list.bullet") }
                        .accessibilityLabel("History")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { SettingsView() } label: { Image(systemName: "gear") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showWeightSheet) { AddWeightView() }
            .sheet(isPresented: $showDoseSheet) { AddDoseView() }
        }
    }

    // MARK: Cards

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let latest = weights.last {
                Text(unit.format(latest.kg))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                if let first = weights.first, weights.count > 1 {
                    let delta = latest.kg - first.kg
                    Text("\(unit.formatChange(delta)) since \(first.date.formatted(.dateTime.day().month().year()))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No weights yet")
                    .font(.title3.weight(.semibold))
                Text("Tap Log weight to add your first one.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var chartCard: some View {
        VStack(spacing: 12) {
            Picker("Range", selection: $range) {
                ForEach(ChartRange.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            TrendChart(weights: weights, doses: doses, unit: unit, range: range)

            HStack(spacing: 6) {
                Rectangle().fill(Color.orange).frame(width: 14, height: 2)
                Text("Dose (labelled when the strength changes)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .cardStyle()
    }

    private var nextDoseCard: some View {
        let last = doses.last
        let next = nextDoseDate(weekday: weekday, lastDose: last?.date)
        return VStack(alignment: .leading, spacing: 6) {
            Text("Next dose")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(describe(next))
                .font(.title3.weight(.semibold))
            if let last {
                Text("Last: \(last.medication) \(formatDose(last.doseMg)), \(last.site.lowercased()), \(last.date.formatted(.dateTime.day().month()))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("Suggested site: \(InjectionSite.next(after: last?.site).rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func describe(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        return date.formatted(.dateTime.weekday(.wide).day().month())
    }
}

/// The next injection day, skipping today if a dose was already logged today.
func nextDoseDate(weekday: Int, lastDose: Date?, now: Date = .now, calendar cal: Calendar = .current) -> Date {
    let today = cal.startOfDay(for: now)
    let from = today.addingTimeInterval(-1)
    var next = cal.nextDate(
        after: from,
        matching: DateComponents(weekday: weekday),
        matchingPolicy: .nextTime
    ) ?? today
    if let lastDose, cal.isDate(lastDose, inSameDayAs: next) {
        next = cal.date(byAdding: .day, value: 7, to: next) ?? next
    }
    return next
}

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
