import SwiftUI

struct HabitDetailView: View {
    let habitId: String
    @EnvironmentObject var habitsStore: HabitsStore
    @Environment(\.dismiss) var dismiss
    @State private var heatmapData: [String: Double] = [:]
    @State private var editingName = false
    @State private var nameValue = ""
    @State private var showIconPicker = false
    @State private var showColorPicker = false

    private var item: HabitWithProgress? { habitsStore.habits.first { $0.id == habitId } }

    let categories = ["health","fitness","study","productivity","mindfulness","finance","personal","custom"]

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            if let item {
                let h = item.habit
                let isBoolean = h.metricType == "boolean"
                let isDone = item.current >= h.goal
                let progress = min(item.current / max(h.goal, 1), 1)
                let unitLabel = displayUnit(h.metricType, h.unit)

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack(spacing: 16) {
                            Button { showIconPicker.toggle(); showColorPicker = false } label: {
                                Image(systemName: sfSymbol(for: h.icon))
                                    .font(.title).foregroundColor(hexColor(h.color))
                                    .frame(width: 64, height: 64)
                                    .background(hexColor(h.color).opacity(0.15))
                                    .cornerRadius(16)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                if editingName {
                                    HStack {
                                        TextField("Name", text: $nameValue)
                                            .font(.titleMedium).foregroundColor(.white)
                                            .onSubmit { saveName() }
                                        Button { saveName() } label: {
                                            Image(systemName: "checkmark").foregroundColor(.white)
                                        }
                                    }
                                } else {
                                    Button { nameValue = h.name; editingName = true } label: {
                                        Text(h.name).font(.titleMedium).foregroundColor(.white)
                                    }
                                }
                                Picker("", selection: Binding(
                                    get: { h.category },
                                    set: { habitsStore.updateHabit(id: h.id, updates: ["category": .string($0)]) }
                                )) {
                                    ForEach(categories, id: \.self) { Text($0.capitalized).tag($0) }
                                }.pickerStyle(.menu).tint(.mutedForeground)
                            }
                            Spacer()
                        }

                        if showIconPicker { iconPickerSection(h: h) }
                        if showColorPicker { colorPickerSection(h: h) }
                        if !showIconPicker && !showColorPicker {
                            Button { showColorPicker = true } label: {
                                Text("Change color").font(.caption2).foregroundColor(.mutedForeground)
                            }
                        }

                        // Progress
                        VStack(spacing: 16) {
                            if isBoolean {
                                HStack {
                                    Text("Today's Status").foregroundColor(.mutedForeground)
                                    Spacer()
                                    Text(isDone ? "Done" : "Not Done")
                                        .font(.title2).fontWeight(.medium)
                                        .foregroundColor(isDone ? .green : .white)
                                }
                                Button { toggleDone(item) } label: {
                                    Text(isDone ? "Mark Undone" : "Mark Done")
                                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                                        .background(isDone ? Color.secondaryBg : Color.white)
                                        .foregroundColor(isDone ? .white : .black)
                                        .cornerRadius(12).fontWeight(.medium)
                                }
                            } else {
                                HStack {
                                    Text("Today's Progress").foregroundColor(.mutedForeground)
                                    Spacer()
                                    Text("\(Int(item.current)) / \(Int(h.goal))\(unitLabel.isEmpty ? "" : " \(unitLabel)")")
                                        .font(.title2).fontWeight(.medium).foregroundColor(.white)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.secondaryBg).frame(height: 10)
                                        Capsule().fill(hexColor(h.color))
                                            .frame(width: geo.size.width * progress, height: 10)
                                    }
                                }.frame(height: 10)

                                Button { toggleDone(item) } label: {
                                    Text(isDone ? "Mark Undone" : "Mark Complete")
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(isDone ? Color.secondaryBg : Color.white)
                                        .foregroundColor(isDone ? .white : .black)
                                        .cornerRadius(12).fontWeight(.medium)
                                }

                                HStack(spacing: 8) {
                                    ForEach(h.increments, id: \.self) { amt in
                                        Button { addProgress(item, amt) } label: {
                                            Text("+\(Int(amt))\(unitLabel.isEmpty ? "" : " \(unitLabel)")")
                                                .font(.caption2).fontWeight(.medium)
                                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                                .background(Color.secondaryBg).foregroundColor(.white)
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(24).background(Color.card).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))

                        // Stats
                        let streakInfo = computeStreak()
                        VStack(spacing: 16) {
                            Text("Statistics").font(.bodyMedium).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading)
                            HStack(spacing: 16) {
                                StatBox(label: "Current Streak", value: "\(streakInfo.0) days")
                                StatBox(label: "Total Logged", value: "\(streakInfo.1) days")
                            }
                        }
                        .padding(24).background(Color.card).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))

                        // Delete
                        Button {
                            Task { await habitsStore.archiveHabit(id: habitId); dismiss() }
                        } label: {
                            HStack {
                                Image(systemName: "trash").font(.body)
                                Text("Delete Habit")
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.destructive.opacity(0.1))
                            .foregroundColor(.destructive).cornerRadius(12).fontWeight(.medium)
                        }
                    }.padding(24)
                }
            } else {
                Text("Habit not found").foregroundColor(.mutedForeground)
            }
        }
        .task { heatmapData = await habitsStore.getHabitLogs(habitId: habitId) }
    }

    private func saveName() {
        if !nameValue.isEmpty {
            habitsStore.updateHabit(id: habitId, updates: ["name": .string(nameValue)])
        }
        editingName = false
    }

    private func toggleDone(_ item: HabitWithProgress) {
        let isDone = item.current >= item.habit.goal
        habitsStore.logProgress(habitId: item.id, value: isDone ? 0 : item.habit.goal)
    }

    private func addProgress(_ item: HabitWithProgress, _ amount: Double) {
        let newVal = min(item.current + amount, item.habit.goal)
        habitsStore.logProgress(habitId: item.id, value: newVal)
    }

    private func computeStreak() -> (Int, Int) {
        let sorted = heatmapData.keys.sorted().reversed()
        var streak = 0
        let today = Date()
        for (i, key) in sorted.enumerated() {
            let expected = Calendar.current.date(byAdding: .day, value: -i, to: today)!
            if key == toLocalDateStr(expected), (heatmapData[key] ?? 0) > 0 {
                streak += 1
            } else { break }
        }
        let total = heatmapData.values.filter { $0 > 0 }.count
        return (streak, total)
    }

    @ViewBuilder
    private func iconPickerSection(h: Habit) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Icon").font(.caption2).foregroundColor(.mutedForeground)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                ForEach(Array(iconOptions.keys.sorted()), id: \.self) { key in
                    Button { habitsStore.updateHabit(id: h.id, updates: ["icon": .string(key)]); showIconPicker = false } label: {
                        Image(systemName: iconOptions[key]!).font(.body)
                            .frame(width: 40, height: 40)
                            .background(h.icon == key ? Color.white : Color.secondaryBg)
                            .foregroundColor(h.icon == key ? .black : .white)
                            .cornerRadius(12)
                    }
                }
            }
        }.padding(16).background(Color.card).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))
    }

    @ViewBuilder
    private func colorPickerSection(h: Habit) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Color").font(.caption2).foregroundColor(.mutedForeground)
            HStack(spacing: 8) {
                ForEach(colorOptions, id: \.self) { c in
                    Button { habitsStore.updateHabit(id: h.id, updates: ["color": .string(c)]); showColorPicker = false } label: {
                        Circle().fill(hexColor(c)).frame(width: 40, height: 40)
                            .overlay(Circle().stroke(h.color == c ? Color.white : Color.clear, lineWidth: 2))
                    }
                }
            }
        }.padding(16).background(Color.card).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))
    }
}

struct StatBox: View {
    let label: String; let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2).foregroundColor(.mutedForeground)
            Text(value).font(.title2).fontWeight(.medium).foregroundColor(.white)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
