import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg
    case stlb

    var id: String { rawValue }

    var label: String {
        switch self {
        case .kg: return "Kilograms"
        case .stlb: return "Stone & pounds"
        }
    }

    static let lbPerKg = 2.2046226218
    static let kgPerStone = 6.35029318

    /// Value used for the chart's y axis (kg, or decimal stone).
    func chartValue(_ kg: Double) -> Double {
        switch self {
        case .kg: return kg
        case .stlb: return kg / Self.kgPerStone
        }
    }

    func axisLabel(_ value: Double) -> String {
        switch self {
        case .kg: return String(format: "%.0f", value)
        case .stlb: return String(format: "%.1f st", value)
        }
    }

    func format(_ kg: Double) -> String {
        switch self {
        case .kg:
            return String(format: "%.1f kg", kg)
        case .stlb:
            let totalLb = (kg * Self.lbPerKg * 10).rounded() / 10
            let stone = Int(totalLb / 14)
            let pounds = totalLb - Double(stone * 14)
            return String(format: "%d st %.1f lb", stone, pounds)
        }
    }

    /// Signed change, e.g. "-3.2 kg" or "-7.1 lb".
    func formatChange(_ deltaKg: Double) -> String {
        switch self {
        case .kg:
            return String(format: "%+.1f kg", deltaKg)
        case .stlb:
            return String(format: "%+.1f lb", deltaKg * Self.lbPerKg)
        }
    }
}

/// Parses decimals typed with either a dot or a comma.
func parseNumber(_ text: String) -> Double? {
    Double(text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
}
