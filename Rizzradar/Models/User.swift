import Foundation

struct User: Identifiable, Codable {
    let id: String
    let username: String
    let email: String
    let groups: [String]?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case email
        case groups
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        groups = try container.decodeIfPresent([String].self, forKey: .groups)
        
        // Try to decode createdAt if present
        if let dateString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: dateString)
        } else {
            createdAt = nil
        }
    }
    
    // Add initializer for preview and testing
    init(id: String, username: String, email: String, groups: [String]? = nil, createdAt: Date? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.groups = groups
        self.createdAt = createdAt
    }
}

// Response types for different API endpoints
struct UserResponse: Codable {
    let success: Bool
    let data: User
}

// Response type for endpoints that return multiple users
struct UsersResponse: Codable {
    let success: Bool
    let data: [User]
} 