import Foundation
import SwiftData

@Model
final class WeightEntry {
    var date: Date
    var kg: Double

    init(date: Date = .now, kg: Double) {
        self.date = date
        self.kg = kg
    }
}

@Model
final class DoseEntry {
    var date: Date
    var medication: String
    var doseMg: Double
    var site: String

    init(date: Date = .now, medication: String, doseMg: Double, site: String) {
        self.date = date
        self.medication = medication
        self.doseMg = doseMg
        self.site = site
    }
}

enum Medication: String, CaseIterable, Identifiable {
    case mounjaro = "Mounjaro"
    case wegovy = "Wegovy"
    case ozempic = "Ozempic"
    case other = "Other"

    var id: String { rawValue }

    /// Pen strengths in mg. "Other" has none: the user types their own.
    var doses: [Double] {
        switch self {
        case .mounjaro: return [2.5, 5, 7.5, 10, 12.5, 15]
        case .wegovy: return [0.25, 0.5, 1, 1.7, 2.4]
        case .ozempic: return [0.25, 0.5, 1, 2]
        case .other: return []
        }
    }
}

enum InjectionSite: String, CaseIterable, Identifiable {
    case abdomenLeft = "Abdomen, left"
    case abdomenRight = "Abdomen, right"
    case thighLeft = "Thigh, left"
    case thighRight = "Thigh, right"
    case armLeft = "Upper arm, left"
    case armRight = "Upper arm, right"

    var id: String { rawValue }

    /// The next site in the rotation after the one last used.
    static func next(after last: String?) -> InjectionSite {
        guard let last, let current = InjectionSite(rawValue: last),
              let index = allCases.firstIndex(of: current) else {
            return allCases[0]
        }
        return allCases[(index + 1) % allCases.count]
    }
}

func formatDose(_ mg: Double) -> String {
    let text = mg.truncatingRemainder(dividingBy: 1) == 0
        ? String(format: "%.0f", mg)
        : String(format: "%g", mg)
    return "\(text) mg"
}
