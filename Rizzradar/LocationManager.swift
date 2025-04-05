import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    
    @Published var heading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: - Initialization
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.headingOrientation = .portrait
        locationManager.headingFilter = 5
    }
    
    // MARK: - Public Methods
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingHeading() {
        locationManager.startUpdatingHeading()
    }
    
    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }
    
    // MARK: - Helper Methods
    func getRelativeDirection(to heading: Double, from deviceHeading: Double) -> String {
        let difference = heading - deviceHeading
        let normalizedDifference = (difference + 360).truncatingRemainder(dividingBy: 360)
        
        switch normalizedDifference {
        case 0...22.5, 337.5...360:
            return "North"
        case 22.5...67.5:
            return "Northeast"
        case 67.5...112.5:
            return "East"
        case 112.5...157.5:
            return "Southeast"
        case 157.5...202.5:
            return "South"
        case 202.5...247.5:
            return "Southwest"
        case 247.5...292.5:
            return "West"
        case 292.5...337.5:
            return "Northwest"
        default:
            return "Unknown"
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingHeading()
        default:
            stopUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }
} 
