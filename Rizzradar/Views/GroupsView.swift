import SwiftUI

struct GroupsView: View {
    @StateObject private var groupService = GroupService.shared
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List {
                if groupService.isLoading {
                    ProgressView()
                } else if groupService.groups.isEmpty {
                    Text("No groups yet")
                        .foregroundColor(.gray)
                } else {
                    ForEach(groupService.groups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            GroupRow(group: group)
                        }
                    }
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingCreateGroup = true }) {
                            Label("Create Group", systemImage: "plus.circle")
                        }
                        Button(action: { showingJoinGroup = true }) {
                            Label("Join Group", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView { success in
                    if success {
                        Task {
                            await groupService.loadGroups()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingJoinGroup) {
                JoinGroupView { success in
                    if success {
                        Task {
                            await groupService.loadGroups()
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .task {
            await groupService.loadGroups()
        }
    }
}

struct GroupRow: View {
    let group: Group
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(group.name)
                .font(.headline)
            Text("\(group.members.count) members")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    GroupsView()
} 