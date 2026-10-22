import SwiftUI
import SwiftData

struct AddDoseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \DoseEntry.date) private var doses: [DoseEntry]

    @AppStorage("medication") private var savedMedication = Medication.mounjaro.rawValue
    @AppStorage("customMedicationName") private var savedCustomName = ""

    @State private var date = Date()
    @State private var medication: Medication = .mounjaro
    @State private var doseMg: Double = 2.5
    @State private var customName = ""
    @State private var customDoseText = ""
    @State private var site: InjectionSite = .abdomenLeft
    @State private var loaded = false

    private var enteredDose: Double? {
        medication == .other ? parseNumber(customDoseText) : doseMg
    }

    private var medicationName: String {
        if medication == .other {
            let trimmed = customName.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "Other" : trimmed
        }
        return medication.rawValue
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    Picker("Medication", selection: $medication) {
                        ForEach(Medication.allCases) { Text($0.rawValue).tag($0) }
                    }
                    if medication == .other {
                        TextField("Name", text: $customName)
                        HStack {
                            TextField("Dose", text: $customDoseText)
                                .keyboardType(.decimalPad)
                            Text("mg").foregroundStyle(.secondary)
                        }
                    } else {
                        Picker("Dose", selection: $doseMg) {
                            ForEach(medication.doses, id: \.self) { Text(formatDose($0)).tag($0) }
                        }
                    }
                }

                Section {
                    Picker("Site", selection: $site) {
                        ForEach(InjectionSite.allCases) { Text($0.rawValue).tag($0) }
                    }
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                } footer: {
                    Text("The site is pre-set to the next one in the rotation.")
                }
            }
            .navigationTitle("Log dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(enteredDose == nil || (enteredDose ?? 0) <= 0)
                }
            }
            .onChange(of: medication) { _, newValue in
                if let first = newValue.doses.first, !newValue.doses.contains(doseMg) {
                    doseMg = first
                }
            }
            .onAppear(perform: loadDefaults)
        }
    }

    private func loadDefaults() {
        guard !loaded else { return }
        loaded = true
        site = InjectionSite.next(after: doses.last?.site)
        medication = Medication(rawValue: savedMedication) ?? .mounjaro
        customName = savedCustomName

        // Default to the most recent dose of the same medication.
        if let last = doses.last(where: { $0.medication == medicationName }) {
            if medication == .other {
                customDoseText = String(format: "%g", last.doseMg)
            } else if medication.doses.contains(last.doseMg) {
                doseMg = last.doseMg
            }
        } else if let first = medication.doses.first {
            doseMg = first
        }
    }

    private func save() {
        guard let dose = enteredDose, dose > 0 else { return }
        context.insert(DoseEntry(date: date, medication: medicationName, doseMg: dose, site: site.rawValue))
        savedMedication = medication.rawValue
        savedCustomName = customName
        dismiss()
    }
}
