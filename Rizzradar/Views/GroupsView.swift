import SwiftUI

struct GroupsView: View {
    @StateObject private var groupService = GroupService.shared
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedGroup: Group?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if groupService.isLoading {
                    ProgressView()
                } else if groupService.groups.isEmpty {
                    VStack(spacing: 20) {
                        Text("No Groups Yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("Create or join a group to get started")
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            Button(action: { showingCreateGroup = true }) {
                                Label("Create Group", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button(action: { showingJoinGroup = true }) {
                                Label("Join Group", systemImage: "person.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    List(groupService.groups) { group in
                        Button {
                            selectedGroup = group
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.name)
                                    .font(.headline)
                                if let description = group.description {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Text("Invite Code: \(group.inviteCode)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                        .foregroundColor(.primary)
                    }
                    .refreshable {
                        await groupService.loadGroups()
                    }
                }
            }
            .navigationTitle("Groups")
            .navigationDestination(item: $selectedGroup) { group in
                GroupDetailView(group: group)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingCreateGroup = true }) {
                            Label("Create Group", systemImage: "plus")
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
                NavigationView {
                    CreateGroupView()
                        .navigationTitle("Create Group")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    showingCreateGroup = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingJoinGroup) {
                NavigationView {
                    JoinGroupView()
                        .navigationTitle("Join Group")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    showingJoinGroup = false
                                }
                            }
                        }
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
        .task {
            await groupService.loadGroups()
        }
    }
}

#Preview {
    GroupsView()
} 