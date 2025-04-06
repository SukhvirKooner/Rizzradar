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
            ZStack {
                // Main content
                if !bluetoothManager.discoveredDevices.isEmpty {
                    // Show the first discovered device
                    DeviceRow(device: bluetoothManager.discoveredDevices[0])
                } else if bluetoothManager.isScanning {
                    // Scanning indicator
                    VStack {
                        ProgressView()
                        Text("Scanning for nearby friends...")
                            .foregroundColor(.secondary)
                    }
                } else {
                    // No friends found
                    VStack(spacing: 16) {
                        Text("No friends found nearby")
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            bluetoothManager.startScanning()
                        }) {
                            Text("Start Scanning")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Menu button
                VStack {
                    HStack {
                        Spacer()
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
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
            .navigationTitle("Nearby Friends")
        }
        .onAppear {
            locationManager.requestAuthorization()
            bluetoothManager.startScanning()
        }
    }
}

struct DeviceRow: View {
    let device: DiscoveredDevice
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        ZStack {
            // Main timelapse and distance display
            Image(systemName: "timelapse")
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.variableColor.reversing)
                .foregroundStyle(.blue.gradient)
                .font(.system(size: 250))
            
            VStack(spacing: 4) {
                Text(device.formattedDistance)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                // Device name below
                Text(device.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BluetoothManager.shared)
        .environmentObject(LocationManager.shared)
        .environmentObject(AuthService.shared)
} 

