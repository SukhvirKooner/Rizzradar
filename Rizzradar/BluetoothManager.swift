import Foundation
import CoreBluetooth
import Combine
import UIKit

class BluetoothManager: NSObject, ObservableObject {
    static let shared = BluetoothManager()
    
    // MARK: - Properties
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    
    @Published var discoveredDevices: [DiscoveredDevice] = []
    @Published var isScanning = false
    
    private let serviceUUID = CBUUID(string: "0D687B81-2CAF-47D8-AA3B-09DDEF3FB023")
    private let characteristicUUID = CBUUID(string: "9B6F709C-D38D-49F5-8916-2ABD47E4197E")
    
    // MARK: - Initialization
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        
        isScanning = true
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    // MARK: - Private Methods
    private func startAdvertising() {
        guard peripheralManager.state == .poweredOn else { return }
        
        let service = CBMutableService(type: serviceUUID, primary: true)
        let characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: .read,
            value: UIDevice.current.identifierForVendor?.uuidString.data(using: .utf8),
            permissions: .readable
        )
        
        service.characteristics = [characteristic]
        peripheralManager.add(service)
        
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: UIDevice.current.name
        ])
    }
    
    private func calculateApproximateDistance(rssi: Int) -> Double {
        // Simple distance estimation based on RSSI
        // This is a basic implementation and might need calibration
        let txPower = -62 // Calibrated RSSI at 1 meter
        if rssi == 0 {
            return -1.0
        }
        
        let ratio = Double(rssi) / Double(txPower)
        if ratio < 1.0 {
            return pow(ratio, 10.0)
        } else {
            return (0.89976) * pow(ratio, 7.7095) + 0.111
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            stopScanning()
            discoveredDevices.removeAll()
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceName = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown Device"
        let distance = calculateApproximateDistance(rssi: RSSI.intValue)
        
        let device = DiscoveredDevice(
            id: peripheral.identifier,
            name: deviceName,
            rssi: RSSI.intValue,
            distance: distance
        )
        
        if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
            discoveredDevices[index] = device
        } else {
            discoveredDevices.append(device)
        }
    }
}

// MARK: - CBPeripheralManagerDelegate
extension BluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            startAdvertising()
        }
    }
}

// MARK: - DiscoveredDevice Model
struct DiscoveredDevice: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int
    let distance: Double
    
    var formattedDistance: String {
        if distance < 0 {
            return "Unknown"
        } else if distance < 1 {
            return "Less than 1m"
        } else {
            return String(format: "%.1fm", distance)
        }
    }
} 
