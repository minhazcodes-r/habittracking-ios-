import SwiftUI

struct CreateHabitView: View {
    @EnvironmentObject var habitsStore: HabitsStore
    @EnvironmentObject var authStore: AuthStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var category = "health"
    @State private var frequency = "daily"
    @State private var metricType = "quantity"
    @State private var unit = "ml"
    @State private var goal = ""
    @State private var icon = "circle"
    @State private var color = "#ffffff"
    @State private var inc1 = ""; @State private var inc2 = ""; @State private var inc3 = ""

    private var isBoolean: Bool { metricType == "boolean" }

    let categories = ["health","fitness","study","productivity","mindfulness","finance","personal","custom"]
    let frequencies = ["daily","weekly","specific days","custom"]
    let metricTypes = ["boolean","count","duration","quantity"]
    let units = ["ml","oz","minutes","hours","pages","reps","sessions"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        InputField(placeholder: "e.g., Drink Water", text: $name, label: "Habit Name")

                        // Icon & Color
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Icon & Color").font(.caption2).foregroundColor(.mutedForeground)
                            HStack(spacing: 16) {
                                Image(systemName: sfSymbol(for: icon))
                                    .font(.title2).foregroundColor(hexColor(color))
                                    .frame(width: 56, height: 56)
                                    .background(hexColor(color).opacity(0.15))
                                    .cornerRadius(16)
                                Text("Preview").font(.caption2).foregroundColor(.mutedForeground)
                            }
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                                ForEach(Array(iconOptions.keys.sorted()), id: \.self) { key in
                                    Button { icon = key } label: {
                                        Image(systemName: iconOptions[key]!)
                                            .font(.body)
                                            .frame(width: 40, height: 40)
                                            .background(icon == key ? Color.white : Color.secondaryBg)
                                            .foregroundColor(icon == key ? .black : .white)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            HStack(spacing: 8) {
                                ForEach(colorOptions, id: \.self) { c in
                                    Button { color = c } label: {
                                        Circle().fill(hexColor(c)).frame(width: 40, height: 40)
                                            .overlay(Circle().stroke(color == c ? Color.white : Color.clear, lineWidth: 2))
                                            .scaleEffect(color == c ? 1.1 : 1)
                                    }
                                }
                            }
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category").font(.caption2).foregroundColor(.mutedForeground)
                            Picker("", selection: $category) {
                                ForEach(categories, id: \.self) { Text($0.capitalized).tag($0) }
                            }.pickerStyle(.menu).tint(.white)
                        }

                        // Frequency
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Frequency").font(.caption2).foregroundColor(.mutedForeground)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(frequencies, id: \.self) { f in
                                    Button { frequency = f } label: {
                                        Text(f.capitalized).font(.caption2).fontWeight(.medium)
                                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                                            .background(frequency == f ? Color.white : Color.secondaryBg)
                                            .foregroundColor(frequency == f ? .black : .white)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }

                        // Metric Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Metric Type").font(.caption2).foregroundColor(.mutedForeground)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(metricTypes, id: \.self) { t in
                                    Button { metricType = t } label: {
                                        Text(t.capitalized).font(.caption2).fontWeight(.medium)
                                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                                            .background(metricType == t ? Color.white : Color.secondaryBg)
                                            .foregroundColor(metricType == t ? .black : .white)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }

                        if !isBoolean {
                            if metricType == "quantity" {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Unit").font(.caption2).foregroundColor(.mutedForeground)
                                    Picker("", selection: $unit) {
                                        ForEach(units, id: \.self) { Text($0).tag($0) }
                                    }.pickerStyle(.menu).tint(.white)
                                }
                            }

                            InputField(placeholder: "e.g., 2000", text: $goal, label: "Goal")

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Increment Buttons").font(.caption2).foregroundColor(.mutedForeground)
                                HStack(spacing: 8) {
                                    InputField(placeholder: "10", text: $inc1)
                                    InputField(placeholder: "25", text: $inc2)
                                    InputField(placeholder: "50", text: $inc3)
                                }
                            }
                        }

                        Button { save() } label: {
                            Text("Save Habit").frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(Color.white).foregroundColor(.black)
                                .cornerRadius(12).fontWeight(.medium)
                        }
                    }.padding(24)
                }
            }
            .navigationTitle("Create Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(.white) }
                }
            }
        }
    }

    private func save() {
        let resolvedUnit = isBoolean ? "done" : (metricType == "count" ? "times" : metricType == "duration" ? "min" : unit)
        let habit = Habit(
            id: UUID().uuidString,
            name: name, category: category, metricType: metricType,
            unit: resolvedUnit,
            goal: isBoolean ? 1 : (Double(goal) ?? 1),
            frequency: frequency,
            increments: isBoolean ? [1] : [Double(inc1) ?? 10, Double(inc2) ?? 25, Double(inc3) ?? 50],
            icon: icon, color: color, position: 0, archived: false
        )
        Task {
            await habitsStore.createHabit(habit)
            dismiss()
        }
    }
}
