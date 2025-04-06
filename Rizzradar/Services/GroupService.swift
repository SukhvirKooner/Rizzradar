import Foundation

@MainActor
class GroupService: ObservableObject {
    static let shared = GroupService()
    
    // Use the provided IP address for the server
    private let baseURL = "http://10.101.52.212:5001/api"
    
    private let authService = AuthService.shared
    
    @Published private(set) var groups: [Group] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    private init() {
        print("GroupService initialized with baseURL: \(baseURL)")
        #if DEBUG
        if let token = authService.getToken() {
            print("Initial auth token: \(token)")
        } else {
            print("WARNING: No auth token available at initialization")
        }
        #endif
    }
    
    private func createRequest(url: URL, method: String, body: [String: Any]? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        guard let token = authService.getToken() else {
            print("❌ No auth token available")
            throw NSError(domain: "GroupService", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Please log in again. No authentication token available."])
        }
        
        // Verify token format
        if !token.contains(".") {
            print("❌ Invalid token format: \(token)")
            throw NSError(domain: "GroupService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid authentication token format. Please log in again."])
        }
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print("✅ Using auth token: \(token)")
        
        if let body = body {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            print("📝 Request body: \(String(data: jsonData, encoding: .utf8) ?? "none")")
        }
        
        print("🔄 Making \(method) request to: \(url.absoluteString)")
        return request
    }
    
    private func handleResponse(_ data: Data, _ response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GroupService", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response type received"])
        }
        
        print("📡 Server response status code: \(httpResponse.statusCode)")
        
        // Print response body for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body: \(responseString)")
        }
        
        // Accept both 200 (OK) and 201 (Created) as success status codes
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            return data
        }
        
        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = errorJson["error"] as? String {
            print("❌ Server error: \(error)")
            throw NSError(domain: "GroupService", code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: error])
        }
        print("❌ Unknown server error with status code: \(httpResponse.statusCode)")
        throw NSError(domain: "GroupService", code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
    }
    
    // Create a new group
    func createGroup(name: String, description: String?) async throws -> Group {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let url = URL(string: "\(baseURL)/groups")!
            print("Creating group with URL: \(url)")
            
            let body = [
                "name": name,
                "description": description
            ]
            
            let request = try createRequest(url: url, method: "POST", body: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseData = try handleResponse(data, response)
            
            let groupResponse = try JSONDecoder().decode(GroupResponse.self, from: responseData)
            await loadGroups()
            return groupResponse.data
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // Join a group using invite code
    func joinGroup(inviteCode: String) async throws -> Group {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let url = URL(string: "\(baseURL)/groups/join")!
            print("Joining group with URL: \(url)")
            
            let body = ["inviteCode": inviteCode]
            let request = try createRequest(url: url, method: "POST", body: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseData = try handleResponse(data, response)
            
            let groupResponse = try JSONDecoder().decode(GroupResponse.self, from: responseData)
            await loadGroups()
            return groupResponse.data
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // Get user's groups
    func loadGroups() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let url = URL(string: "\(baseURL)/groups/my-groups")!
            print("Loading groups with URL: \(url)")
            
            let request = try createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseData = try handleResponse(data, response)
            
            let groupsResponse = try JSONDecoder().decode(GroupsResponse.self, from: responseData)
            groups = groupsResponse.data
            print("Successfully loaded \(groups.count) groups")
        } catch {
            print("Error loading groups: \(error)")
            self.error = error.localizedDescription
            groups = []
        }
    }
    
    // Get group members
    func getGroupMembers(groupId: String) async throws -> [User] {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let url = URL(string: "\(baseURL)/groups/\(groupId)/members")!
            print("Getting group members with URL: \(url)")
            
            let request = try createRequest(url: url, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseData = try handleResponse(data, response)
            
            // Print raw response for debugging
            print("Raw members response: \(String(data: responseData, encoding: .utf8) ?? "none")")
            
            do {
                let usersResponse = try JSONDecoder().decode(UsersResponse.self, from: responseData)
                print("Successfully loaded \(usersResponse.data.count) members")
                return usersResponse.data
            } catch {
                print("❌ JSON Decoding error: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, _):
                        print("Missing key: \(key)")
                    case .valueNotFound(let type, _):
                        print("Missing value for type: \(type)")
                    case .typeMismatch(let type, _):
                        print("Type mismatch for type: \(type)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                throw error
            }
        } catch {
            print("❌ Network or other error: \(error)")
            self.error = error.localizedDescription
            throw error
        }
    }
} 