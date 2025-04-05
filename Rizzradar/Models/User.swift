import Foundation

struct User: Identifiable, Codable {
    let id: String
    let username: String
    let email: String
    let groups: [String]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case email
        case groups
        case createdAt
    }
}

struct UserResponse: Codable {
    let success: Bool
    let data: User
} 