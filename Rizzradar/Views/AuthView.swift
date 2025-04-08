import SwiftUI

struct AuthView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var groupService = GroupService.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var buttonScale: CGFloat = 1.0
    @State private var showFields = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Logo and App Name
                    VStack(spacing: 15) {
                        Image(systemName: "person.2.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(showFields ? 360 : 0))
                            .animation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0), value: showFields)
                        
                        Text("RizzRadar")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.top, 50)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        if isSignUp {
                            // Username field with animation
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
                            .transition(.move(edge: .top).combined(with: .opacity))
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
                        .offset(x: showFields ? 0 : -UIScreen.main.bounds.width)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0).delay(0.1), value: showFields)
                        
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
                        .offset(x: showFields ? 0 : UIScreen.main.bounds.width)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0).delay(0.2), value: showFields)
                        
                        if isSignUp {
                            // Invite code field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Invite Code")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                HStack {
                                    Image(systemName: "ticket.fill")
                                        .foregroundColor(.blue)
                                    TextField("Enter invite code", text: $inviteCode)
                                        .textContentType(.oneTimeCode)
                                        .autocapitalization(.none)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: isSignUp)
                    
                    // Sign In/Up Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                            buttonScale = 0.9
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                                buttonScale = 1.0
                            }
                            handleAuth()
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: isValid ? [.blue, .blue.opacity(0.8)] : [.gray, .gray],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 50)
                        .padding(.horizontal)
                    }
                    .scaleEffect(buttonScale)
                    .disabled(isLoading || !isValid)
                    
                    // Toggle Sign In/Up
                    Button(action: {
                        withAnimation {
                            isSignUp.toggle()
                            errorMessage = nil
                        }
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                            .padding(.top)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showFields = true
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                withAnimation {
                    errorMessage = nil
                    isLoading = false
                }
            }
        } message: {
            if let error = errorMessage {
                Text(error)
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