import Foundation

struct Habit: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var category: String
    var metricType: String
    var unit: String
    var goal: Double
    var frequency: String
    var increments: [Double]
    var icon: String
    var color: String
    var position: Int
    var archived: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, category, unit, goal, frequency, increments, icon, color, position, archived
        case metricType = "metric_type"
    }
}

struct HabitWithProgress: Identifiable, Equatable {
    var habit: Habit
    var current: Double
    var id: String { habit.id }
}
