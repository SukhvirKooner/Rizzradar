import Foundation

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    private let baseURL = "http://localhost:5001/api/auth"
    
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
        self.authToken = "demo-token"
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
        self.authToken = "demo-token"
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