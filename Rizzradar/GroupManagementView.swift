import SwiftUI

struct GroupManagementView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var showingCreateGroupSheet = false
    @State private var showingJoinGroupSheet = false
    @State private var groupName = ""
    @State private var password = ""
    @State private var selectedGroup: Group?
    @State private var joinPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // Current Group Section
                if let currentGroup = bluetoothManager.currentGroup {
                    Section("Current Group") {
                        VStack(alignment: .leading) {
                            Text(currentGroup.name)
                                .font(.headline)
                            Text(currentGroup.isHost ? "Host" : "Member")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if currentGroup.isHost {
                            // Pending Requests
                            ForEach(currentGroup.pendingRequests, id: \.self) { userId in
                                HStack {
                                    Text("Join Request")
                                        .font(.subheadline)
                                    Spacer()
                                    Button("Approve") {
                                        bluetoothManager.approveJoinRequest(for: userId)
                                    }
                                    .buttonStyle(.bordered)
                                    Button("Deny") {
                                        bluetoothManager.denyJoinRequest(for: userId)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                }
                            }
                            
                            // Members List
                            ForEach(currentGroup.members, id: \.self) { memberId in
                                HStack {
                                    Text(memberId == currentGroup.hostId ? "👑 Host" : "👤 Member")
                                    Spacer()
                                    if memberId == UIDevice.current.identifierForVendor {
                                        Text("(You)")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Available Groups Section
                Section("Available Groups") {
                    if bluetoothManager.discoveredGroups.isEmpty {
                        Text("No groups found nearby")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(bluetoothManager.discoveredGroups) { group in
                            Button {
                                selectedGroup = group
                                showingJoinGroupSheet = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(group.name)
                                            .font(.headline)
                                        Text("\(group.members.count) members")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "person.badge.plus")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                if bluetoothManager.currentGroup == nil {
                    Button {
                        showingCreateGroupSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroupSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("Group Details")) {
                            TextField("Group Name", text: $groupName)
                            SecureField("Password", text: $password)
                        }
                    }
                    .navigationTitle("Create Group")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingCreateGroupSheet = false
                        },
                        trailing: Button("Create") {
                            bluetoothManager.createGroup(name: groupName, password: password)
                            showingCreateGroupSheet = false
                            groupName = ""
                            password = ""
                        }
                        .disabled(groupName.isEmpty || password.isEmpty)
                    )
                }
            }
            .sheet(isPresented: $showingJoinGroupSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("Join Group")) {
                            if let group = selectedGroup {
                                Text(group.name)
                                    .font(.headline)
                                SecureField("Password", text: $joinPassword)
                            }
                        }
                    }
                    .navigationTitle("Join Group")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingJoinGroupSheet = false
                            joinPassword = ""
                        },
                        trailing: Button("Join") {
                            if let group = selectedGroup {
                                bluetoothManager.joinGroup(group, withPassword: joinPassword)
                            }
                            showingJoinGroupSheet = false
                            joinPassword = ""
                        }
                        .disabled(joinPassword.isEmpty)
                    )
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    GroupManagementView()
        .environmentObject(BluetoothManager.shared)
} 