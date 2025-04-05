import Foundation
import CoreBluetooth
import Combine
import UIKit
import CryptoKit
import CommonCrypto
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

// MARK: - Group Model
struct Group: Codable, Identifiable {
    let id: UUID
    let name: String
    let hostId: UUID
    var members: [UUID]
    var pendingRequests: [UUID]
    let passwordHash: String
    let salt: String
    
    var isHost: Bool {
        hostId == UIDevice.current.identifierForVendor
    }
}

// MARK: - Message Types
enum MessageType: String, Codable {
    case joinRequest
    case joinResponse
    case locationUpdate
    case leaveGroup
}

struct JoinRequestData: Codable {
    let deviceName: String
    let passwordHash: String
}

struct JoinResponseData: Codable {
    let approved: Bool
    let key: String?
    let reason: String?
}

struct Message: Codable {
    let type: MessageType
    let senderId: UUID
    let groupId: UUID
    let data: Data
    let timestamp: Date
}

class BluetoothManager: NSObject, ObservableObject {
    static let shared = BluetoothManager()
    
    // MARK: - Properties
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private var discoveredPeripherals: [CBPeripheral: DiscoveredDevice] = [:]
    private let db = Firestore.firestore()
    private var connectedPeripherals: [CBPeripheral] = []
    private var characteristics: [CBUUID: CBCharacteristic] = [:]
    private var advertisingService: CBMutableService?
    private var advertisingCharacteristic: CBMutableCharacteristic?
    
    @Published var currentGroup: Group?
    @Published var discoveredGroups: [Group] = []
    @Published var discoveredDevices: [DiscoveredDevice] = []
    @Published var isScanning = false
    @Published var isAdvertising = false
    
    private let serviceUUID = CBUUID(string: "0D687B81-2CAF-47D8-AA3B-09DDEF3FB023")
    private let characteristicUUID = CBUUID(string: "9B6F709C-D38D-49F5-8916-2ABD47E4197E")
    private var symmetricKey: SymmetricKey?
    
    // MARK: - Initialization
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Group Management
    func createGroup(name: String, password: String) {
        guard let deviceId = UIDevice.current.identifierForVendor else { return }
        
        // Generate salt and hash password
        let salt = generateSalt()
        let passwordHash = hashPassword(password, salt: salt)
        
        let group = Group(
            id: UUID(),
            name: name,
            hostId: deviceId,
            members: [deviceId],
            pendingRequests: [],
            passwordHash: passwordHash,
            salt: salt
        )
        
        // Save group to Firebase
        saveGroupToDatabase(group)
        
        currentGroup = group
        generateGroupKey()
        startAdvertising()
    }
    
    func joinGroup(_ group: Group, withPassword password: String) {
        guard let deviceId = UIDevice.current.identifierForVendor else { return }
        
        // Hash the provided password with group's salt
        let attemptedHash = hashPassword(password, salt: group.salt)
        
        let joinRequestData = JoinRequestData(
            deviceName: UIDevice.current.name,
            passwordHash: attemptedHash
        )
        
        let joinRequest = Message(
            type: MessageType.joinRequest,
            senderId: deviceId,
            groupId: group.id,
            data: try! JSONEncoder().encode(joinRequestData),
            timestamp: Date()
        )
        
        sendMessage(joinRequest)
    }
    
    func approveJoinRequest(for userId: UUID, requestData: JoinRequestData) {
        guard var group = currentGroup, group.isHost else { return }
        
        // Verify password hash
        if requestData.passwordHash != group.passwordHash {
            denyJoinRequest(for: userId, reason: "Incorrect password")
            return
        }
        
        group.members.append(userId)
        group.pendingRequests.removeAll { $0 == userId }
        
        // Update group in Firebase
        updateGroupInDatabase(group)
        
        currentGroup = group
        
        // Convert SymmetricKey to Data safely
        let keyData: Data
        if let key = symmetricKey {
            keyData = key.withUnsafeBytes { bytes in
                Data(bytes)
            }
        } else {
            keyData = Data()
        }
        
        let responseData = JoinResponseData(
            approved: true,
            key: keyData.base64EncodedString(),
            reason: nil
        )
        
        let response = Message(
            type: MessageType.joinResponse,
            senderId: group.hostId,
            groupId: group.id,
            data: try! JSONEncoder().encode(responseData),
            timestamp: Date()
        )
        
        sendMessage(response)
    }
    
    func denyJoinRequest(for userId: UUID, reason: String = "Request denied") {
        guard var group = currentGroup, group.isHost else { return }
        
        group.pendingRequests.removeAll { $0 == userId }
        currentGroup = group
        
        let responseData = JoinResponseData(
            approved: false,
            key: nil,
            reason: reason
        )
        
        let response = Message(
            type: MessageType.joinResponse,
            senderId: group.hostId,
            groupId: group.id,
            data: try! JSONEncoder().encode(responseData),
            timestamp: Date()
        )
        
        sendMessage(response)
    }
    
    // MARK: - Database Operations
    private func saveGroupToDatabase(_ group: Group) {
        do {
            try db.collection("groups").document(group.id.uuidString).setData(from: group)
        } catch {
            print("Error saving group: \(error)")
        }
    }
    
    private func updateGroupInDatabase(_ group: Group) {
        do {
            try db.collection("groups").document(group.id.uuidString).setData(from: group)
        } catch {
            print("Error updating group: \(error)")
        }
    }
    
    // MARK: - Key Generation and Management
    private func generateGroupKey() {
        symmetricKey = SymmetricKey(size: .bits256)
    }
    
    // MARK: - Message Handling
    private func sendMessage(_ message: Message, to peripheral: CBPeripheral? = nil) {
        guard let data = try? JSONEncoder().encode(message) else { return }
        
        if let encryptedData = encrypt(data) {
            if let peripheral = peripheral {
                // Send to specific peripheral
                guard let characteristic = characteristics[characteristicUUID] else { return }
                peripheral.writeValue(encryptedData, for: characteristic, type: .withResponse)
            } else {
                // Broadcast to all connected peripherals
                guard let characteristic = advertisingCharacteristic else {
                    // Create characteristic if it doesn't exist
                    advertisingCharacteristic = CBMutableCharacteristic(
                        type: characteristicUUID,
                        properties: [.read, .notify, .write],
                        value: encryptedData,
                        permissions: [.readable, .writeable]
                    )
                    
                    if advertisingService == nil {
                        advertisingService = CBMutableService(type: serviceUUID, primary: true)
                        advertisingService?.characteristics = [advertisingCharacteristic!]
                        peripheralManager.add(advertisingService!)
                    }
                    return
                }
                
                peripheralManager.updateValue(encryptedData, for: characteristic, onSubscribedCentrals: nil)
            }
        }
    }
    
    // MARK: - Password Handling
    private func generateSalt() -> String {
        var saltData = Data(count: 32) // 32 bytes for salt
        let result = saltData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            fatalError("Failed to generate salt")
        }
        
        return saltData.base64EncodedString()
    }
    
    private func hashPassword(_ password: String, salt: String) -> String {
        guard let passwordData = password.data(using: .utf8),
              let saltData = Data(base64Encoded: salt) else {
            return ""
        }
        
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        var saltBytes = [UInt8](repeating: 0, count: saltData.count)
        var passwordBytes = [UInt8](repeating: 0, count: passwordData.count)
        
        saltData.copyBytes(to: &saltBytes, count: saltData.count)
        passwordData.copyBytes(to: &passwordBytes, count: passwordData.count)
        
        CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            password,
            passwordData.count,
            saltBytes,
            saltData.count,
            CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256),
            10000,
            &hash,
            Int(CC_SHA256_DIGEST_LENGTH)
        )
        
        return Data(hash).base64EncodedString()
    }
    
    // MARK: - Encryption
    private func encrypt(_ data: Data) -> Data? {
        guard let key = symmetricKey else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    private func decrypt(_ data: Data) -> Data? {
        guard let key = symmetricKey else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
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
        
        // Create and configure the service
        advertisingService = CBMutableService(type: serviceUUID, primary: true)
        advertisingCharacteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read, .notify, .write],
            value: UIDevice.current.identifierForVendor?.uuidString.data(using: .utf8),
            permissions: [.readable, .writeable]
        )
        
        advertisingService?.characteristics = [advertisingCharacteristic!]
        peripheralManager.add(advertisingService!)
        
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: UIDevice.current.name
        ])
    }
    
    private func calculateApproximateDistance(rssi: Int) -> Double {
        // Simple distance estimation based on RSSI
        // This is a basic implementation and might need calibration
        let txPower = -59 // Calibrated RSSI at 1 meter
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
