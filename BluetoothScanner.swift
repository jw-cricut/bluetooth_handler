import Foundation
import CoreBluetooth

@objc public class BluetoothScanner: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager?
    var discoveredDevices: Set<UUID> = []
    var scanResults: [[String: String]] = []

    private let scanQueue = DispatchQueue(label: "com.klaus.bluetoothScanQueue")
    private let scanSemaphore = DispatchSemaphore(value: 0)

    @objc public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: scanQueue)
    }

    @objc public func startScan() {
        print("Starting BLE scan (Swift)...")
        centralManager?.scanForPeripherals(withServices: nil, options: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.centralManager?.stopScan()
            print("Scan complete.")
            CFRunLoopStop(CFRunLoopGetCurrent())
        }

        CFRunLoopRun()
    }

    public func startScanSync() -> [[String: String]] {
        print("Starting synchronous BLE scan (Swift)...")
        discoveredDevices.removeAll()
        scanResults.removeAll()

        // Wait for Bluetooth to power on
        while centralManager?.state != .poweredOn {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }

        centralManager?.scanForPeripherals(withServices: nil, options: nil)

        // Stop scan after 5 seconds
        scanQueue.asyncAfter(deadline: .now() + 5) {
            self.centralManager?.stopScan()
            self.scanSemaphore.signal()
        }

        // Block until scan completes or timeout
        _ = scanSemaphore.wait(timeout: .now() + 6)

        return scanResults
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            print("Bluetooth not ready: \(central.state.rawValue)")
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didDiscover peripheral: CBPeripheral,
                               advertisementData: [String : Any],
                               rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(peripheral.identifier) {
            discoveredDevices.insert(peripheral.identifier)
            let deviceName = peripheral.name ?? "Unnamed"
            scanResults.append([
                "name": deviceName,
                "uuid": peripheral.identifier.uuidString
            ])
            print("Discovered: \(deviceName) (\(peripheral.identifier)) - RSSI: \(RSSI)")
        }
    }

    @objc public func connectToDevice(with uuid: String) {
        print("Attempting to connect to device with UUID: \(uuid)")
        // TODO: Implement actual connection logic using CoreBluetooth
    }
}

