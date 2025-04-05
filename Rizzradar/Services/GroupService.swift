import Foundation

@MainActor
class GroupService: ObservableObject {
    static let shared = GroupService()
    private let baseURL = "http://localhost:5001/api"
    private let authService = AuthService.shared
    
    @Published private(set) var groups: [Group] = []
    @Published private(set) var isLoading = false
    
    private init() {}
    
    // Create a new group
    func createGroup(name: String, description: String?) async throws -> Group {
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "\(baseURL)/groups")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = authService.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = [
            "name": name,
            "description": description
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GroupResponse.self, from: data)
        await loadGroups()
        return response.data
    }
    
    // Join a group using invite code
    func joinGroup(inviteCode: String) async throws -> Group {
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "\(baseURL)/groups/join")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = authService.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["inviteCode": inviteCode]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GroupResponse.self, from: data)
        await loadGroups()
        return response.data
    }
    
    // Get user's groups
    func loadGroups() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URL(string: "\(baseURL)/groups/my-groups")!
            var request = URLRequest(url: url)
            
            // Add auth token if available
            if let token = authService.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(GroupsResponse.self, from: data)
            groups = response.data
        } catch {
            print("Error loading groups: \(error)")
            groups = []
        }
    }
    
    // Get group members
    func getGroupMembers(groupId: String) async throws -> [User] {
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "\(baseURL)/groups/\(groupId)/members")!
        var request = URLRequest(url: url)
        
        // Add auth token if available
        if let token = authService.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(UsersResponse.self, from: data)
        return response.data
    }
} 