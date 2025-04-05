import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        if authService.isAuthenticated {
            TabView {
                NearbyFriendsView()
                    .environmentObject(bluetoothManager)
                    .environmentObject(locationManager)
                    .tabItem {
                        Label("Nearby", systemImage: "person.2.fill")
                    }
                
                GroupsView()
                    .tabItem {
                        Label("Groups", systemImage: "person.3.fill")
                    }
            }
        } else {
            AuthView()
        }
    }
}

struct NearbyFriendsView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if bluetoothManager.isScanning {
                        HStack {
                            ProgressView()
                            Text("Scanning for nearby friends...")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Not scanning")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Nearby Friends")) {
                    if bluetoothManager.discoveredDevices.isEmpty {
                        Text("No friends found nearby")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(bluetoothManager.discoveredDevices) { device in
                            DeviceRow(device: device)
                        }
                    }
                }
            }
            .navigationTitle("Nearby Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            if bluetoothManager.isScanning {
                                bluetoothManager.stopScanning()
                            } else {
                                bluetoothManager.startScanning()
                            }
                        }) {
                            Label(
                                bluetoothManager.isScanning ? "Stop Scanning" : "Start Scanning",
                                systemImage: bluetoothManager.isScanning ? "stop.circle" : "play.circle"
                            )
                        }
                        
                        Button(role: .destructive, action: {
                            authService.signOut()
                        }) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            locationManager.requestAuthorization()
        }
    }
}

struct DeviceRow: View {
    let device: DiscoveredDevice
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(device.name)
                .font(.headline)
            
            HStack {
                Image(systemName: "rssi")
                Text(device.formattedDistance)
                    .foregroundColor(.secondary)
                
                if let heading = locationManager.heading {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(locationManager.getRelativeDirection(
                        to: heading.trueHeading,
                        from: heading.trueHeading
                    ))
                    .foregroundColor(.secondary)
                }
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(BluetoothManager.shared)
        .environmentObject(LocationManager.shared)
        .environmentObject(AuthService.shared)
} 
