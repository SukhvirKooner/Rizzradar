import Foundation

struct Group: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String?
    let creator: String
    let members: [String]
    let inviteCode: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case description
        case creator
        case members
        case inviteCode
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        creator = try container.decode(String.self, forKey: .creator)
        members = try container.decode([String].self, forKey: .members)
        inviteCode = try container.decode(String.self, forKey: .inviteCode)
        
        // Parse ISO 8601 date string with fractional seconds
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            createdAt = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match ISO 8601 format")
        }
    }
    
    // Add initializer for preview and testing
    init(id: String, name: String, description: String?, creator: String, members: [String], inviteCode: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.description = description
        self.creator = creator
        self.members = members
        self.inviteCode = inviteCode
        self.createdAt = createdAt
    }
    
    // Implement hash(into:) for Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement == for Hashable conformance
    static func == (lhs: Group, rhs: Group) -> Bool {
        lhs.id == rhs.id
    }
}

struct GroupResponse: Codable {
    let success: Bool
    let data: Group
}

struct GroupsResponse: Codable {
    let success: Bool
    let data: [Group]
} 