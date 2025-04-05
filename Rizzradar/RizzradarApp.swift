import SwiftUI

@main
struct RizzradarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(BluetoothManager.shared)
                .environmentObject(LocationManager.shared)
        }
    }
}
