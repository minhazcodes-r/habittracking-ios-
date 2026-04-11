import SwiftUI
import Supabase

private struct CalendarLog: Codable {
    let habitId: String
    let date: String
    let value: Double

    enum CodingKeys: String, CodingKey {
        case habitId = "habit_id"
        case date, value
    }
}

@MainActor
class CalendarStore: ObservableObject {
    @Published var dayLogs: [String: [String: Double]] = [:]
    @Published var viewMonth: Int
    @Published var viewYear: Int

    init() {
        let cal = Calendar.current
        let now = Date()
        viewMonth = cal.component(.month, from: now)
        viewYear = cal.component(.year, from: now)
    }

    func fetchMonthLogs(userId: String) async {
        let cal = Calendar.current
        var comps = DateComponents(year: viewYear, month: viewMonth, day: 1)
        guard let start = cal.date(from: comps) else { return }
        comps.month = viewMonth + 1
        comps.day = 0
        guard let end = cal.date(from: comps) else { return }

        let startStr = toLocalDateStr(start)
        let endStr = toLocalDateStr(end)

        do {
            let logs: [CalendarLog] = try await supabase
                .from("habit_logs")
                .select()
                .eq("user_id", value: userId)
                .gte("date", value: startStr)
                .lte("date", value: endStr)
                .execute()
                .value

            var result: [String: [String: Double]] = [:]
            for log in logs {
                result[log.date, default: [:]][log.habitId] = log.value
            }
            dayLogs = result
        } catch {
            print("fetchMonthLogs error: \(error)")
        }
    }

    func prevMonth() {
        if viewMonth == 1 { viewMonth = 12; viewYear -= 1 }
        else { viewMonth -= 1 }
    }

    func nextMonth() {
        if viewMonth == 12 { viewMonth = 1; viewYear += 1 }
        else { viewMonth += 1 }
    }
}
