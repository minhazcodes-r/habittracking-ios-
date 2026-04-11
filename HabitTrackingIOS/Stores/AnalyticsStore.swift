import SwiftUI
import Supabase

private struct AnalyticsLog: Codable {
    let habitId: String
    let date: String
    let value: Double

    enum CodingKeys: String, CodingKey {
        case habitId = "habit_id"
        case date, value
    }
}

@MainActor
class AnalyticsStore: ObservableObject {
    @Published var weeklyData: [Double] = Array(repeating: 0, count: 7)
    @Published var avgCompletion: Double = 0

    func fetchWeeklyData(userId: String, habits: [HabitWithProgress]) async {
        let cal = Calendar.current
        let today = Date()
        guard let weekStart = cal.date(byAdding: .day, value: -6, to: today) else { return }

        let startStr = toLocalDateStr(weekStart)
        let endStr = toLocalDateStr(today)

        do {
            let logs: [AnalyticsLog] = try await supabase
                .from("habit_logs")
                .select()
                .eq("user_id", value: userId)
                .gte("date", value: startStr)
                .lte("date", value: endStr)
                .execute()
                .value

            let goalMap = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0.habit.goal) })
            var daily: [Double] = Array(repeating: 0, count: 7)

            for i in 0..<7 {
                let day = cal.date(byAdding: .day, value: i - 6, to: today)!
                let dayStr = toLocalDateStr(day)
                let dayLogs = logs.filter { $0.date == dayStr }
                guard !habits.isEmpty else { continue }
                let pct = dayLogs.reduce(0.0) { sum, log in
                    let goal = goalMap[log.habitId] ?? 1
                    return sum + min(log.value / goal, 1.0)
                } / Double(habits.count)
                daily[i] = pct
            }

            weeklyData = daily
            avgCompletion = daily.reduce(0, +) / 7.0
        } catch {
            print("fetchWeeklyData error: \(error)")
        }
    }
}
