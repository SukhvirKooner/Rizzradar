import SwiftUI

struct JoinGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var groupService = GroupService.shared
    
    @State private var inviteCode = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section {
                TextField("Invite Code", text: $inviteCode)
                    .textContentType(.none)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Section {
                Button(action: joinGroup) {
                    if groupService.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Join Group")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(inviteCode.isEmpty || groupService.isLoading)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: groupService.error) { error in
            if let error = error {
                errorMessage = error
                showingError = true
            }
        }
    }
    
    private func joinGroup() {
        Task {
            do {
                _ = try await groupService.joinGroup(inviteCode: inviteCode)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    NavigationView {
        JoinGroupView()
    }
} 