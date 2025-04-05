import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let onComplete: (Bool) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Group Name", text: $name)
                    TextField("Description (Optional)", text: $description)
                }
                
                Section {
                    Button(action: createGroup) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Create Group")
                        }
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .navigationTitle("Create Group")
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
    
    private func createGroup() {
        isLoading = true
        Task {
            do {
                _ = try await GroupService.shared.createGroup(
                    name: name,
                    description: description.isEmpty ? nil : description
                )
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

struct CreateGroupView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGroupView { _ in }
    }
} 