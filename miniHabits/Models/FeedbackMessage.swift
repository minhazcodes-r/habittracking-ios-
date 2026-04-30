import Foundation

struct FeedbackMessage: Codable {
    let userId: String
    let type: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case type, message
        case userId = "user_id"
    }
}
