import SwiftUI

@main
struct RizzradarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(BluetoothManager.shared)
                .environmentObject(LocationManager.shared)
        }
    }
}
