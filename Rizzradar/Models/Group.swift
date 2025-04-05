import Foundation

struct Group: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let creator: User
    let members: [User]
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
}

struct GroupResponse: Codable {
    let success: Bool
    let data: Group
}

struct GroupsResponse: Codable {
    let success: Bool
    let data: [Group]
}

struct UsersResponse: Codable {
    let success: Bool
    let data: [User]
} 