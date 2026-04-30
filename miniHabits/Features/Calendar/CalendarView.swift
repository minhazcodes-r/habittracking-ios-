import SwiftUI
import Supabase

struct CalendarScreenView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var habitsStore: HabitsStore
    @State private var viewMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var viewYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedDay: Int? = nil
    @State private var selectedCategory = "all"
    @State private var dayLogs: [String: [String: Double]] = [:]

    private let dayNames = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
    private let monthNames = ["","January","February","March","April","May","June","July","August","September","October","November","December"]

    private var daysInMonth: Int {
        let comps = DateComponents(year: viewYear, month: viewMonth + 1, day: 0)
        return Calendar.current.date(from: comps)!.get(.day)
    }
    private var startingDayOfWeek: Int {
        let comps = DateComponents(year: viewYear, month: viewMonth, day: 1)
        return Calendar.current.component(.weekday, from: Calendar.current.date(from: comps)!) - 1
    }

    private var categories: [String] {
        let cats = Set(habitsStore.habits.map { $0.habit.category })
        return ["all"] + cats.sorted()
    }

    private var filteredHabits: [HabitWithProgress] {
        selectedCategory == "all" ? habitsStore.habits : habitsStore.habits.filter { $0.habit.category == selectedCategory }
    }

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calendar").font(.titleLarge).foregroundColor(.white)
                        HStack(spacing: 16) {
                            Button { prevMonth() } label: {
                                Image(systemName: "chevron.left").foregroundColor(.white)
                                    .frame(width: 32, height: 32).background(Color.secondaryBg).clipShape(Circle())
                            }
                            Text("\(monthNames[viewMonth]) \(String(viewYear))")
                                .font(.bodyMedium).foregroundColor(.mutedForeground)
                            Button { nextMonth() } label: {
                                Image(systemName: "chevron.right").foregroundColor(.white)
                                    .frame(width: 32, height: 32).background(Color.secondaryBg).clipShape(Circle())
                            }
                        }
                    }

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                Button { selectedCategory = cat } label: {
                                    Text(cat == "all" ? "All" : cat.capitalized)
                                        .font(.caption2).fontWeight(.medium)
                                        .padding(.horizontal, 16).padding(.vertical, 8)
                                        .background(selectedCategory == cat ? Color.white : Color.secondaryBg)
                                        .foregroundColor(selectedCategory == cat ? .black : .white)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }

                    // Calendar grid
                    VStack(spacing: 8) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(dayNames, id: \.self) { d in
                                Text(d).font(.small).foregroundColor(.mutedForeground).frame(maxWidth: .infinity)
                            }
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(0..<startingDayOfWeek, id: \.self) { _ in Color.clear.frame(height: 36) }
                            ForEach(1...daysInMonth, id: \.self) { day in
                                let isToday = day == Calendar.current.component(.day, from: Date()) &&
                                    viewMonth == Calendar.current.component(.month, from: Date()) &&
                                    viewYear == Calendar.current.component(.year, from: Date())
                                let isSelected = day == selectedDay
                                Button { selectedDay = day } label: {
                                    Text("\(day)").font(.caption2).fontWeight(.medium)
                                        .frame(maxWidth: .infinity).frame(height: 36)
                                        .background(isSelected ? Color.white : isToday ? Color.muted : completionColor(day))
                                        .foregroundColor(isSelected ? .black : .white)
                                        .cornerRadius(8)
                                        .overlay(isToday && !isSelected ? RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2) : nil)
                                }
                            }
                        }
                    }
                    .padding(24).background(Color.card).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))

                    // Selected day detail
                    if let day = selectedDay {
                        let dateStr = String(format: "%04d-%02d-%02d", viewYear, viewMonth, day)
                        let logs = dayLogs[dateStr] ?? [:]
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(monthNames[viewMonth]) \(day), \(String(viewYear))")
                                .font(.bodyMedium).foregroundColor(.white)
                            if filteredHabits.isEmpty {
                                Text("No habits in this category").foregroundColor(.mutedForeground)
                            } else {
                                ForEach(filteredHabits) { h in
                                    let ul = displayUnit(h.habit.metricType, h.habit.unit)
                                    HStack {
                                        Text(h.habit.name).foregroundColor(.mutedForeground)
                                        Spacer()
                                        Text("\(Int(logs[h.id] ?? 0)) / \(Int(h.habit.goal))\(ul.isEmpty ? "" : " \(ul)")")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .padding(24).background(Color.card).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))
                    }
                }.padding(24).padding(.bottom, 80)
            }
        }
        .task { await fetchLogs() }
        .onChange(of: viewMonth) { _ in Task { await fetchLogs() } }
        .onChange(of: viewYear) { _ in Task { await fetchLogs() } }
    }

    private func prevMonth() {
        selectedDay = nil
        if viewMonth == 1 { viewMonth = 12; viewYear -= 1 } else { viewMonth -= 1 }
    }
    private func nextMonth() {
        selectedDay = nil
        if viewMonth == 12 { viewMonth = 1; viewYear += 1 } else { viewMonth += 1 }
    }

    private func completionColor(_ day: Int) -> Color {
        let dateStr = String(format: "%04d-%02d-%02d", viewYear, viewMonth, day)
        guard let logs = dayLogs[dateStr], !filteredHabits.isEmpty else { return Color.secondaryBg }
        let filteredIds = Set(filteredHabits.map { $0.id })
        let relevant = logs.keys.filter { filteredIds.contains($0) }.count
        let ratio = Double(relevant) / Double(filteredHabits.count)
        if ratio >= 0.8 { return .white }
        if ratio >= 0.5 { return .mutedForeground }
        if ratio > 0 { return .muted }
        return Color.secondaryBg
    }

    private func fetchLogs() async {
        guard let uid = authStore.user?.id.uuidString else { return }
        let from = String(format: "%04d-%02d-01", viewYear, viewMonth)
        let to = String(format: "%04d-%02d-%02d", viewYear, viewMonth, daysInMonth)
        do {
            struct LogRow: Codable { let habit_id: String; let date: String; let value: Double }
            let data: [LogRow] = try await supabase.from("habit_logs").select()
                .eq("user_id", value: uid).gte("date", value: from).lte("date", value: to)
                .execute().value
            var map: [String: [String: Double]] = [:]
            for l in data {
                map[l.date, default: [:]][l.habit_id] = l.value
            }
            dayLogs = map
        } catch {}
    }
}

extension Date {
    func get(_ component: Calendar.Component) -> Int {
        Calendar.current.component(component, from: self)
    }
}
