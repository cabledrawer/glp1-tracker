import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]
    @Query(sort: \DoseEntry.date, order: .reverse) private var doses: [DoseEntry]
    @AppStorage("unit") private var unitRaw = WeightUnit.kg.rawValue

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    var body: some View {
        List {
            Section("Doses") {
                if doses.isEmpty {
                    Text("No doses logged yet").foregroundStyle(.secondary)
                }
                ForEach(doses) { dose in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(dose.medication), \(formatDose(dose.doseMg))")
                        Text("\(dose.date.formatted(.dateTime.day().month().year())) · \(dose.site)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(doses[index]) }
                }
            }

            Section("Weights") {
                if weights.isEmpty {
                    Text("No weights logged yet").foregroundStyle(.secondary)
                }
                ForEach(weights) { entry in
                    HStack {
                        Text(entry.date.formatted(.dateTime.day().month().year()))
                        Spacer()
                        Text(unit.format(entry.kg)).foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(weights[index]) }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
