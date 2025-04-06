import SwiftUI

struct GroupDetailView: View {
    let group: Group
    @StateObject private var viewModel: GroupDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(group: Group) {
        self.group = group
        self._viewModel = StateObject(wrappedValue: GroupDetailViewModel(group: group))
    }
    
    var body: some View {
        List {
            Section {
                if let description = group.description {
                    Text(description)
                        .foregroundColor(.secondary)
                }
                
                Button(action: { viewModel.showingInviteCode.toggle() }) {
                    HStack {
                        Text("Invite Code")
                        Spacer()
                        if viewModel.showingInviteCode {
                            Text(group.inviteCode)
                                .foregroundColor(.blue)
                        } else {
                            Text("Tap to show")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Section(header: Text("Members (\(viewModel.members.count))")) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if viewModel.members.isEmpty && viewModel.errorMessage == nil {
                    Text("No members found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(viewModel.members) { member in
                        HStack {
                            Text(member.username)
                            if member.id == group.creator {
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
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("Retry") {
                Task {
                    await viewModel.loadMembers()
                }
            }
            Button("OK", role: .cancel) {
                viewModel.dismissError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .refreshable {
            await viewModel.loadMembers()
        }
        .task {
            await viewModel.loadMembers()
        }
    }
}

@MainActor
class GroupDetailViewModel: ObservableObject {
    private let group: Group
    private let groupService = GroupService.shared
    private var loadingTask: Task<Void, Never>?
    
    @Published var members: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    @Published var showingInviteCode = false
    
    init(group: Group) {
        self.group = group
    }
    
    func loadMembers() async {
        guard !isLoading else { return }
        
        // Cancel any existing loading task
        loadingTask?.cancel()
        
        let task = Task {
            isLoading = true
            errorMessage = nil
            showingError = false
            
            do {
                let loadedMembers = try await groupService.getGroupMembers(groupId: group.id)
                if !Task.isCancelled {
                    members = loadedMembers
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        loadingTask = task
        await task.value
    }
    
    func dismissError() {
        errorMessage = nil
        showingError = false
    }
    
    deinit {
        loadingTask?.cancel()
    }
}

struct GroupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupDetailView(group: Group(
                id: "1",
                name: "Test Group",
                description: "A test group",
                creator: "1",
                members: ["1"],
                inviteCode: "ABC123",
                createdAt: Date()
            ))
        }
    }
} 