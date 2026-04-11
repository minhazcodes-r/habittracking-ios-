import Foundation

struct HabitLog: Codable {
    let habitId: String
    let date: String
    let value: Double

    enum CodingKeys: String, CodingKey {
        case date, value
        case habitId = "habit_id"
    }
}
