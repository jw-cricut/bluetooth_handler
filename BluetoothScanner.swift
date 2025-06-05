import Foundation
import CoreBluetooth

// Required: Make this global or import the bridge if in a separate module
// public var connectionCallback: BLEConnectionCallback?

@objc public class BluetoothScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    var discoveredDevices: Set<UUID> = []
    var scanResults: [[String: String]] = []
    var targetUUID: UUID?
    var targetPeripheral: CBPeripheral?

    // ✅ Added for tracking the connected device
    private var connectedPeripheral: CBPeripheral?

    private let scanQueue = DispatchQueue(label: "com.klaus.bluetoothScanQueue")
    private let scanSemaphore = DispatchSemaphore(value: 0)

    @objc public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: scanQueue)
    }

    @objc public func startScan() {
        print("Starting BLE scan (Swift)...")
        centralManager?.scanForPeripherals(withServices: nil, options: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
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

        while centralManager?.state != .poweredOn {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }

        centralManager?.scanForPeripherals(withServices: nil, options: nil)

        scanQueue.asyncAfter(deadline: .now() + 5) {
            self.centralManager?.stopScan()
            self.scanSemaphore.signal()
        }

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

        if peripheral.identifier == targetUUID {
            print("Found target peripheral. Connecting...")
            self.targetPeripheral = peripheral
            self.targetPeripheral?.delegate = self
            centralManager?.stopScan()
            centralManager?.connect(peripheral, options: nil)
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Successfully connected to \(peripheral.identifier)")
        peripheral.delegate = self
        peripheral.discoverServices(nil)

        // ✅ Track connected peripheral
        self.connectedPeripheral = peripheral

        if let callback = connectionCallback {
            let uuidCString = strdup(peripheral.identifier.uuidString)
            callback(UnsafePointer(uuidCString!))
        }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect to \(peripheral.identifier): \(error?.localizedDescription ?? "unknown error")")
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Error discovering services: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }
        for service in services {
            print("🔍 Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ Error discovering characteristics for service \(service.uuid): \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            print("📍 Discovered characteristic: \(characteristic.uuid) for service \(service.uuid)")

            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                print("📡 Subscribed to notifications for \(characteristic.uuid)")
            }

            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
                print("📖 Reading value for \(characteristic.uuid)")
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Error receiving update from \(characteristic.uuid): \(error.localizedDescription)")
            return
        }

        if let value = characteristic.value {
            print("📬 Received update from \(characteristic.uuid): \(value as NSData)")
        }
    }

    @objc public func connectToDevice(with uuid: String) {
        print("Attempting to connect to device with UUID: \(uuid)")

        guard let uuidObj = UUID(uuidString: uuid) else {
            print("Invalid UUID format.")
            return
        }

        self.targetUUID = uuidObj

        let peripherals = centralManager?.retrievePeripherals(withIdentifiers: [uuidObj]) ?? []

        if let peripheral = peripherals.first {
            print("Found previously known peripheral. Connecting...")
            self.targetPeripheral = peripheral
            self.targetPeripheral?.delegate = self
            centralManager?.connect(peripheral, options: nil)
        } else {
            print("Peripheral not found in known devices. Scanning for peripheral...")
            centralManager?.scanForPeripherals(withServices: nil, options: nil)

            scanQueue.asyncAfter(deadline: .now() + 10) { [weak self] in
                guard let self = self else { return }
                if self.targetPeripheral == nil {
                    print("Failed to discover peripheral with UUID: \(uuid) within timeout.")
                    self.centralManager?.stopScan()
                }
            }
        }
    }

    // ✅ Disconnect currently connected device
    @objc public func disconnect() {
        if let peripheral = connectedPeripheral {
            print("🔌 Disconnecting from peripheral: \(peripheral.identifier)")
            centralManager?.cancelPeripheralConnection(peripheral)
            connectedPeripheral = nil
        } else {
            print("ℹ️ No connected peripheral to disconnect.")
        }
    }
}