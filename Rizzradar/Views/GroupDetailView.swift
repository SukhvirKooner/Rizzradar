import SwiftUI

struct GroupDetailView: View {
    let group: Group
    @State private var members: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingInviteCode = false
    
    var body: some View {
        List {
            Section {
                if let description = group.description {
                    Text(description)
                        .foregroundColor(.secondary)
                }
                
                Button(action: { showingInviteCode.toggle() }) {
                    HStack {
                        Text("Invite Code")
                        Spacer()
                        if showingInviteCode {
                            Text(group.inviteCode)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Tap to show")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section("Members (\(members.count))") {
                if isLoading {
                    ProgressView()
                } else {
                    ForEach(members) { member in
                        HStack {
                            Text(member.username)
                            if member.id == group.creator.id {
                                Spacer()
                                Text("Creator")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(group.name)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await loadMembers()
        }
    }
    
    private func loadMembers() async {
        isLoading = true
        do {
            members = try await GroupService.shared.getGroupMembers(groupId: group.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct GroupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupDetailView(group: Group(
                id: "1",
                name: "Test Group",
                description: "A test group",
                creator: User(id: "1", username: "test", email: "test@example.com", groups: [], createdAt: Date()),
                members: [],
                inviteCode: "ABC123",
                createdAt: Date()
            ))
        }
    }
} 