import Foundation
import CoreBluetooth
import ObjectiveC.runtime

@objc public class BluetoothScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    var discoveredDevices: Set<UUID> = []
    var scanCallback: ((String, String, Int) -> Void)?
    var finishedCallback: (() -> Void)?
    
    // Map from UUID strings to peripherals
    private var peripheralMap: [String: CBPeripheral] = [:]

    override public init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - CoreBluetooth State Updates

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            print("Bluetooth is not available.")
        }
    }

    // MARK: - Scan With JSON Results

    public struct DiscoveredDevice: Codable {
        var name: String
        var uuid: String
        var rssi: Int
    }

    public func performScanAndReturnResults() -> [DiscoveredDevice] {
        var results: [DiscoveredDevice] = []
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()

        self.startScan(callback: { name, uuid, rssi in
            results.append(DiscoveredDevice(name: name, uuid: uuid, rssi: rssi))
        }) {
            dispatchGroup.leave()
        }

        dispatchGroup.wait()
        return results
    }

    public func startScan(callback: @escaping (String, String, Int) -> Void,
                          finished: @escaping () -> Void) {
        self.scanCallback = callback
        self.finishedCallback = finished
        self.discoveredDevices.removeAll()
        self.peripheralMap.removeAll()

        // If powered on, scan now
        if let manager = self.centralManager, manager.state == .poweredOn {
            manager.scanForPeripherals(withServices: nil, options: nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                manager.stopScan()
                finished()
            }
        } else {
            print("Bluetooth not ready or powered off.")
            finished()
        }
    }

    // MARK: - Peripheral Discovery

    public func centralManager(_ central: CBCentralManager,
                               didDiscover peripheral: CBPeripheral,
                               advertisementData: [String : Any],
                               rssi RSSI: NSNumber) {
        guard !discoveredDevices.contains(peripheral.identifier) else { return }
        discoveredDevices.insert(peripheral.identifier)

        let uuidString = peripheral.identifier.uuidString
        peripheralMap[uuidString] = peripheral
        let name = peripheral.name ?? "Unnamed"
        scanCallback?(name, uuidString, RSSI.intValue)
    }

    // MARK: - Connect to Peripheral

    @objc public func connectToDevice(uuidString: String) {
        guard let peripheral = peripheralMap[uuidString] else {
            print("No known peripheral with UUID \(uuidString)")
            return
        }
        print("🔌 Connecting to device: \(uuidString)")
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to device: \(peripheral.identifier.uuidString)")
        // Optional: discover services, characteristics, etc.
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect to device: \(peripheral.identifier.uuidString), error: \(error?.localizedDescription ?? "unknown")")
    }
}

// MARK: - C-callable Function

@_cdecl("ConnectToBLEDevice")
public func ConnectToBLEDevice(_ cAddress: UnsafePointer<CChar>) {
    let uuidString = String(cString: cAddress)
    DispatchQueue.main.async {
        let scanner = BluetoothScannerSingleton.shared.scanner
        scanner.connectToDevice(uuidString: uuidString)
    }
}

// Singleton helper
class BluetoothScannerSingleton {
    static let shared = BluetoothScannerSingleton()
    let scanner = BluetoothScanner()
}

@objc public func connectToDeviceWithUUID(_ uuid: String) {
    // Example: implement actual connection logic here
    print("Connecting to device with UUID: \(uuid)")
    
    // You might want to persist centralManager, scan results, etc. here for actual connection
    // For now, this is a placeholder
}

