import SwiftUI
import Charts

enum ChartRange: String, CaseIterable, Identifiable {
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"

    var id: String { rawValue }

    var startDate: Date? {
        let cal = Calendar.current
        switch self {
        case .threeMonths: return cal.date(byAdding: .month, value: -3, to: .now)
        case .sixMonths: return cal.date(byAdding: .month, value: -6, to: .now)
        case .year: return cal.date(byAdding: .year, value: -1, to: .now)
        case .all: return nil
        }
    }
}

struct TrendChart: View {
    let weights: [WeightEntry]
    let doses: [DoseEntry]
    let unit: WeightUnit
    let range: ChartRange

    private var visibleWeights: [WeightEntry] {
        guard let start = range.startDate else { return weights }
        return weights.filter { $0.date >= start }
    }

    private var visibleDoses: [DoseEntry] {
        guard let start = range.startDate else { return doses }
        return doses.filter { $0.date >= start }
    }

    /// Doses where the strength changed (or the first one ever logged).
    private func isChange(_ dose: DoseEntry) -> Bool {
        guard let index = doses.firstIndex(where: { $0.persistentModelID == dose.persistentModelID }) else {
            return false
        }
        if index == 0 { return true }
        return doses[index - 1].doseMg != dose.doseMg
    }

    var body: some View {
        Chart {
            ForEach(visibleDoses) { dose in
                let change = isChange(dose)
                RuleMark(x: .value("Dose", dose.date))
                    .foregroundStyle(Color.orange.opacity(change ? 0.8 : 0.25))
                    .lineStyle(StrokeStyle(lineWidth: change ? 1.5 : 1, dash: [4, 3]))
                    .annotation(
                        position: .top,
                        alignment: .leading,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        if change {
                            Text(formatDose(dose.doseMg))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }
            }

            ForEach(visibleWeights) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", unit.chartValue(entry.kg))
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Color.accentColor)

                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", unit.chartValue(entry.kg))
                )
                .foregroundStyle(Color.accentColor)
                .symbolSize(30)
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let number = value.as(Double.self) {
                        Text(unit.axisLabel(number))
                    }
                }
            }
        }
        .frame(height: 240)
        .overlay {
            if visibleWeights.isEmpty {
                Text("Log your first weight to see the chart")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
