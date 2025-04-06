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
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                // Content
                ScrollView {
                    VStack(spacing: 30) {
                        // App icon or logo
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(.blue.gradient)
                            .symbolEffect(.bounce)
                        
                        Text("Rizzradar")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.blue.gradient)
                        
                        // Input fields
                        VStack(spacing: 20) {
                            if isSignUp {
                                // Username field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Username")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.blue)
                                        TextField("Enter your username", text: $username)
                                            .textContentType(.username)
                                            .autocapitalization(.none)
                                            .foregroundColor(.primary)
                                    }
                                    .padding()
                                    .background(Color(uiColor: .systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                }
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.blue)
                                    TextField("Enter your email", text: $email)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.blue)
                                    SecureField("Enter your password", text: $password)
                                        .textContentType(isSignUp ? .newPassword : .password)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Sign in/up button
                        Button(action: handleAuth) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: isValid ? [.blue, .blue.opacity(0.8)] : [.gray, .gray],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .foregroundColor(.white)
                            .shadow(color: isValid ? .blue.opacity(0.3) : .clear, radius: 5, x: 0, y: 2)
                        }
                        .disabled(isLoading || !isValid)
                        .padding(.horizontal)
                        
                        // Toggle sign in/up
                        Button(action: { 
                            withAnimation {
                                isSignUp.toggle()
                            }
                        }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .foregroundStyle(.blue.gradient)
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 40)
                }
            }
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