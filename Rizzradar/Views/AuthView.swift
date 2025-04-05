import SwiftUI

struct AuthView: View {
    @StateObject private var authService = AuthService.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    if isSignUp {
                        TextField("Username", text: $username)
                            .textContentType(.username)
                            .autocapitalization(.none)
                    }
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                }
                
                Section {
                    Button(action: handleAuth) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                        }
                    }
                    .disabled(isLoading || !isValid)
                }
                
                Section {
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle(isSignUp ? "Sign Up" : "Sign In")
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private var isValid: Bool {
        if isSignUp {
            return !username.isEmpty && !email.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func handleAuth() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isSignUp {
                    _ = try await authService.signUp(
                        username: username,
                        email: email,
                        password: password
                    )
                } else {
                    _ = try await authService.signIn(
                        email: email,
                        password: password
                    )
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    AuthView()
} 