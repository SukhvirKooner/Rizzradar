import Foundation

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    // Use the provided IP address for the server
    private let baseURL = "http://10.101.52.212:5001/api/auth"
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: String?
    
    private init() {}


    func signIn(email: String, password: String) async throws {
        // Demo: Skip backend call and directly authenticate
        self.isAuthenticated = true
        self.currentUser = User(
            id: "demo-user-id",
            username: email.split(separator: "@").first.map(String.init) ?? "demo-user",
            email: email,
            groups: [],
            createdAt: Date()
        )
        // Using a properly formatted JWT token for demo
        self.authToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImRlbW8tdXNlci1pZCIsImlhdCI6MTcxMDI0OTYwMCwiZXhwIjoxNzEwMzM2MDAwfQ.demo-signature"
    }
    
    func signUp(username: String, email: String, password: String) async throws {
        // Demo: Skip backend call and directly authenticate
        self.isAuthenticated = true
        self.currentUser = User(
            id: "demo-user-id",
            username: username,
            email: email,
            groups: [],
            createdAt: Date()
        )
        // Using a properly formatted JWT token for demo
        self.authToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImRlbW8tdXNlci1pZCIsImlhdCI6MTcxMDI0OTYwMCwiZXhwIjoxNzEwMzM2MDAwfQ.demo-signature"
    }
    
    func signOut() {
        self.isAuthenticated = false
        self.currentUser = nil
        self.authToken = nil
    }
    
    func getToken() -> String? {
        return authToken
    }
} 