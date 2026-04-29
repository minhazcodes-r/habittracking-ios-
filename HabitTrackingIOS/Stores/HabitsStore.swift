import SwiftUI
import Supabase

@MainActor
class HabitsStore: ObservableObject {
    @Published var habits: [HabitWithProgress] = []
    @Published var isLoading = true
    @Published var lastError: String?

    private var userId: String?

    var today: String { toLocalDateStr(Date()) }

    func fetchHabits(userId: String) async {
        self.userId = userId

        do {
            let habitsData: [Habit] = try await supabase
                .from("habits")
                .select()
                .eq("user_id", value: userId)
                .eq("archived", value: false)
                .order("position", ascending: true)
                .execute()
                .value

            let logsData: [HabitLog] = try await supabase
                .from("habit_logs")
                .select()
                .eq("user_id", value: userId)
                .eq("date", value: today)
                .execute()
                .value

            let logMap = Dictionary(uniqueKeysWithValues: logsData.map { ($0.habitId, $0.value) })

            self.habits = habitsData.map { h in
                HabitWithProgress(habit: h, current: logMap[h.id] ?? 0)
            }
        } catch {
            lastError = error.localizedDescription
        }
        self.isLoading = false
    }

    func createHabit(_ habit: Habit) async {
        guard let userId else { return }
        struct InsertHabit: Encodable {
            let id: String; let name: String; let category: String
            let metric_type: String; let unit: String; let goal: Double
            let frequency: String; let increments: [Double]; let icon: String
            let color: String; let position: Int; let archived: Bool; let user_id: String
        }
        let insert = InsertHabit(
            id: habit.id, name: habit.name, category: habit.category,
            metric_type: habit.metricType, unit: habit.unit, goal: habit.goal,
            frequency: habit.frequency, increments: habit.increments, icon: habit.icon,
            color: habit.color, position: habit.position, archived: false, user_id: userId
        )
        do {
            try await supabase.from("habits").insert(insert).execute()
            await fetchHabits(userId: userId)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func updateHabit(id: String, updates: [String: AnyJSON]) {
        if let idx = habits.firstIndex(where: { $0.id == id }) {
            var h = habits[idx].habit
            for (key, val) in updates {
                switch key {
                case "name": if case .string(let v) = val { h.name = v }
                case "category": if case .string(let v) = val { h.category = v }
                case "icon": if case .string(let v) = val { h.icon = v }
                case "color": if case .string(let v) = val { h.color = v }
                default: break
                }
            }
            habits[idx].habit = h
        }
        Task {
            do {
                try await supabase.from("habits").update(updates).eq("id", value: id).execute()
            } catch {
                await MainActor.run { self.lastError = error.localizedDescription }
            }
        }
    }

    func logProgress(habitId: String, value: Double) {
        guard let userId else { return }
        if let idx = habits.firstIndex(where: { $0.id == habitId }) {
            habits[idx].current = value
        }
        struct LogUpsert: Encodable {
            let habit_id: String; let user_id: String; let date: String; let value: Double
        }
        let log = LogUpsert(habit_id: habitId, user_id: userId, date: today, value: value)
        Task {
            do {
                try await supabase.from("habit_logs").upsert(log, onConflict: "habit_id,user_id,date").execute()
            } catch {
                await MainActor.run { self.lastError = error.localizedDescription }
            }
        }
    }

    func archiveHabit(id: String) async {
        habits.removeAll { $0.id == id }
        do {
            try await supabase.from("habits").update(["archived": AnyJSON.bool(true)]).eq("id", value: id).execute()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func reorderHabits(_ reordered: [HabitWithProgress]) {
        habits = reordered
        for (i, h) in reordered.enumerated() {
            Task {
                do {
                    try await supabase.from("habits").update(["position": AnyJSON.integer(i)]).eq("id", value: h.id).execute()
                } catch {
                    await MainActor.run { self.lastError = error.localizedDescription }
                }
            }
        }
    }

    func getHabitLogs(habitId: String, days: Int = 84) async -> [String: Double] {
        guard let userId else { return [:] }
        let from = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        do {
            let logs: [HabitLog] = try await supabase
                .from("habit_logs")
                .select()
                .eq("habit_id", value: habitId)
                .eq("user_id", value: userId)
                .gte("date", value: toLocalDateStr(from))
                .execute()
                .value
            return Dictionary(uniqueKeysWithValues: logs.map { ($0.date, $0.value) })
        } catch { return [:] }
    }
}
