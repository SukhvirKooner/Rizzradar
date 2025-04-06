import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var groupService = GroupService.shared
    
    @State private var name = ""
    @State private var description = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section {
                TextField("Group Name", text: $name)
                    .textContentType(.name)
                    .autocapitalization(.words)
                
                TextField("Description (Optional)", text: $description)
                    .textContentType(.none)
                    .autocapitalization(.sentences)
            }
            
            Section {
                Button(action: createGroup) {
                    if groupService.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Group")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(name.isEmpty || groupService.isLoading)
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
    
    private func createGroup() {
        Task {
            do {
                _ = try await groupService.createGroup(name: name, description: description.isEmpty ? nil : description)
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
        CreateGroupView()
    }
} 