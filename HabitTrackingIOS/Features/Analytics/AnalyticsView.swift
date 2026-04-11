import SwiftUI
import Supabase

struct AnalyticsView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var habitsStore: HabitsStore
    @State private var weeklyData: [Double] = Array(repeating: 0, count: 7)
    @State private var avgCompletion: Double = 0

    let dayLabels = ["M","T","W","T","F","S","S"]

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analytics").font(.titleLarge).foregroundColor(.white)
                        Text("Your progress overview").foregroundColor(.mutedForeground)
                    }

                    HStack(spacing: 16) {
                        StatCard(icon: "target", label: "Active Habits", value: "\(habitsStore.habits.count)")
                        StatCard(icon: "rosette", label: "Avg Completion", value: "\(Int(avgCompletion))%")
                    }

                    // Weekly chart
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .frame(width: 40, height: 40).background(Color.secondaryBg).clipShape(Circle())
                                .foregroundColor(.white)
                            VStack(alignment: .leading) {
                                Text("This Week").font(.bodyMedium).foregroundColor(.white)
                                Text("Last 7 days").font(.caption2).foregroundColor(.mutedForeground)
                            }
                        }
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(0..<7, id: \.self) { i in
                                VStack(spacing: 4) {
                                    ZStack(alignment: .bottom) {
                                        RoundedRectangle(cornerRadius: 4).fill(Color.secondaryBg).frame(height: 80)
                                        RoundedRectangle(cornerRadius: 4).fill(Color.white)
                                            .frame(height: max(2, 80 * weeklyData[i] / 100))
                                    }.frame(height: 80)
                                    Text(dayLabels[i]).font(.small).foregroundColor(.mutedForeground)
                                }.frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(24).background(Color.card).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))

                    // Per-habit bars
                    if !habitsStore.habits.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Habits").font(.bodyMedium).foregroundColor(.white)
                            ForEach(habitsStore.habits) { item in
                                let pct = item.habit.goal > 0 ? min(item.current / item.habit.goal, 1) : 0
                                VStack(spacing: 8) {
                                    HStack {
                                        Text(item.habit.name).foregroundColor(.white)
                                        Spacer()
                                        Text("\(Int(pct * 100))%").font(.caption2).foregroundColor(.mutedForeground)
                                    }
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color.secondaryBg).frame(height: 6)
                                            Capsule().fill(Color.white).frame(width: geo.size.width * pct, height: 6)
                                        }
                                    }.frame(height: 6)
                                }
                            }
                        }
                        .padding(24).background(Color.card).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))
                    }
                }.padding(24).padding(.bottom, 80)
            }
        }
        .task { await fetchWeekly() }
    }

    private func fetchWeekly() async {
        guard let uid = authStore.user?.id.uuidString, !habitsStore.habits.isEmpty else { return }
        let today = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: today)!
        do {
            struct LogRow: Codable { let habit_id: String; let date: String; let value: Double }
            let data: [LogRow] = try await supabase.from("habit_logs").select()
                .eq("user_id", value: uid)
                .gte("date", value: toLocalDateStr(weekAgo))
                .lte("date", value: toLocalDateStr(today))
                .execute().value

            let goalMap = Dictionary(uniqueKeysWithValues: habitsStore.habits.map { ($0.id, $0.habit.goal) })
            var dailyScores: [String: [Double]] = [:]
            for l in data {
                let goal = goalMap[l.habit_id] ?? 1
                dailyScores[l.date, default: []].append(min(l.value / goal, 1) * 100)
            }

            var weekly: [Double] = []
            for i in 0..<7 {
                let d = Calendar.current.date(byAdding: .day, value: i, to: weekAgo)!
                let key = toLocalDateStr(d)
                let scores = dailyScores[key] ?? []
                weekly.append(scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count))
            }
            weeklyData = weekly
            let nonZero = weekly.filter { $0 > 0 }
            avgCompletion = nonZero.isEmpty ? 0 : nonZero.reduce(0, +) / Double(nonZero.count)
        } catch {}
    }
}

struct StatCard: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).foregroundColor(.white)
                .frame(width: 40, height: 40).background(Color.secondaryBg).clipShape(Circle())
            Text(label).font(.caption2).foregroundColor(.mutedForeground)
            Text(value).font(.titleLarge).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24).background(Color.card).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor))
    }
}
