import SwiftUI
import SwiftData

struct AddWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("unit") private var unitRaw = WeightUnit.kg.rawValue

    @State private var date = Date()
    @State private var kgText = ""
    @State private var stoneText = ""
    @State private var lbText = ""

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    /// The entered weight in kg, or nil if it isn't valid.
    private var enteredKg: Double? {
        let kg: Double?
        switch unit {
        case .kg:
            kg = parseNumber(kgText)
        case .stlb:
            guard let stone = parseNumber(stoneText), let pounds = parseNumber(lbText.isEmpty ? "0" : lbText) else {
                return nil
            }
            kg = (stone * 14 + pounds) / WeightUnit.lbPerKg
        }
        guard let kg, kg >= 20, kg <= 400 else { return nil }
        return kg
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weight") {
                    switch unit {
                    case .kg:
                        HStack {
                            TextField("0.0", text: $kgText)
                                .keyboardType(.decimalPad)
                            Text("kg").foregroundStyle(.secondary)
                        }
                    case .stlb:
                        HStack {
                            TextField("0", text: $stoneText)
                                .keyboardType(.numberPad)
                            Text("st").foregroundStyle(.secondary)
                            TextField("0.0", text: $lbText)
                                .keyboardType(.decimalPad)
                            Text("lb").foregroundStyle(.secondary)
                        }
                    }
                }
                Section {
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                }
            }
            .navigationTitle("Log weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let kg = enteredKg {
                            context.insert(WeightEntry(date: date, kg: kg))
                            dismiss()
                        }
                    }
                    .disabled(enteredKg == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
