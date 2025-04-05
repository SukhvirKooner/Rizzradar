import SwiftUI

// MARK: - Create Group Sheet View
struct CreateGroupSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Binding var groupName: String
    @Binding var password: String
    
    var body: some View {
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
                    dismiss()
                },
                trailing: Button("Create") {
                    bluetoothManager.createGroup(name: groupName, password: password)
                    dismiss()
                }
                .disabled(groupName.isEmpty || password.isEmpty)
            )
        }
    }
}

// MARK: - Join Group Sheet View
struct JoinGroupSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bluetoothManager: BluetoothManager
    let selectedGroup: Group?
    @Binding var joinPassword: String
    
    var body: some View {
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
                    dismiss()
                },
                trailing: Button("Join") {
                    if let group = selectedGroup {
                        bluetoothManager.joinGroup(group, withPassword: joinPassword)
                    }
                    dismiss()
                }
                .disabled(joinPassword.isEmpty)
            )
        }
    }
}

// MARK: - Group Info View
private struct GroupInfoView: View {
    let name: String
    let isHost: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .font(.headline)
            Text(isHost ? "Host" : "Member")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Current Group Section View
struct CurrentGroupSection: View {
    let currentGroup: Group
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var pendingRequestsData: [UUID: JoinRequestData] = [:]
    
    var body: some View {
        Section {
            LazyVStack(alignment: .leading, spacing: 8) {
                GroupInfoView(name: currentGroup.name, isHost: currentGroup.isHost)
                
                if currentGroup.isHost {
                    ForEach(currentGroup.pendingRequests, id: \.self) { userId in
                        HStack {
                            Text("Join Request")
                                .font(.subheadline)
                            Spacer()
                            Button("Approve") {
                                let requestData = JoinRequestData(
                                    deviceName: "Unknown Device",
                                    passwordHash: currentGroup.passwordHash
                                )
                                bluetoothManager.approveJoinRequest(for: userId, requestData: requestData)
                            }
                            .buttonStyle(.bordered)
                            Button("Deny") {
                                bluetoothManager.denyJoinRequest(for: userId)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    
                    ForEach(currentGroup.members, id: \.self) { memberId in
                        HStack {
                            Text(memberId == currentGroup.hostId ? "👑 Host" : "👤 Member")
                            Spacer()
                            if let deviceId = UIDevice.current.identifierForVendor {
                                if memberId == deviceId {
                                    Text("(You)")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Current Group")
        }
    }
}

// MARK: - Main View
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
                if let currentGroup = bluetoothManager.currentGroup {
                    CurrentGroupSection(currentGroup: currentGroup)
                }
                
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
                CreateGroupSheet(groupName: $groupName, password: $password)
                    .environmentObject(bluetoothManager)
            }
            .sheet(isPresented: $showingJoinGroupSheet) {
                JoinGroupSheet(selectedGroup: selectedGroup, joinPassword: $joinPassword)
                    .environmentObject(bluetoothManager)
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
