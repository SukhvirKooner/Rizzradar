import SwiftUI

struct JoinGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var groupService = GroupService.shared
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let onComplete: (Bool) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Invite Code", text: $inviteCode)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button(action: joinGroup) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Join Group")
                        }
                    }
                    .disabled(inviteCode.isEmpty || isLoading)
                }
            }
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private func joinGroup() {
        isLoading = true
        Task {
            do {
                _ = try await groupService.joinGroup(inviteCode: inviteCode)
                await MainActor.run {
                    onComplete(true)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct JoinGroupView_Previews: PreviewProvider {
    static var previews: some View {
        JoinGroupView { _ in }
    }
} 