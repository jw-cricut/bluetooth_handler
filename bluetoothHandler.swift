/* #if os(macOS)
import Foundation
import CoreBluetooth

enum BluetoothDeviceClass: String {
    case class1 = "Class 1"
    case class2 = "Class 2"
    case class3 = "Class 3"
    case unknown = "Unknown"
}

class BluetoothDevice {
    let deviceClass: BluetoothDeviceClass
    let range: Double // Range in meters
    
    init(deviceClass: BluetoothDeviceClass, range: Double) {
        self.deviceClass = deviceClass
        self.range = range
    }
}

class BluetoothManager: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on.")
            // Start scanning for nearby Bluetooth peripherals
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        case .poweredOff:
            print("Bluetooth is powered off.")
        case .unsupported:
            print("Bluetooth is not supported on this device.")
        case .unauthorized:
            print("Bluetooth usage is unauthorized.")
        case .resetting:
            print("Bluetooth is resetting.")
        case .unknown:
            print("Bluetooth state is unknown.")
        @unknown default:
            fatalError("Unknown Bluetooth state.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered peripheral: \(peripheral)")
        
        var deviceClass: BluetoothDeviceClass = .unknown
        
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            let bytes = [UInt8](manufacturerData)
            if bytes.count >= 3 {
                switch bytes[2] {
                case 0x01:
                    deviceClass = .class1
                case 0x02:
                    deviceClass = .class2
                case 0x03:
                    deviceClass = .class3
                default:
                    break
                }
            }
        }
        
        print("Device Class: \(deviceClass.rawValue)")
        print("RSSI: \(RSSI) dBm")
    }
}

// Create an instance of the BluetoothManager to start Bluetooth management
let bluetoothManager = BluetoothManager()

// Keep the run loop running to continue Bluetooth operations
//RunLoop.main.run()

//cmd arguments


#endif */

import Foundation
import CoreBluetooth

class BluetoothScanner: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager?
    var devices: [CBPeripheral] = []
    var connectedDevice: CBPeripheral?
    var discoveredDeviceUUIDs: Set<UUID> = []
    let scanDuration: TimeInterval = 15 // Scan duration in seconds

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is powered on.")
            print("1. Scan for devices")
            print("2. Connect to a device")
            print("3. Disconnect from device")
            print("4. Exit")
            processUserInput()
        } else {
            print("Bluetooth is not available.")
        }
    }

    func processUserInput() {
        print("Enter your choice:")
        if let choice = readLine(), let option = Int(choice) {
            switch option {
            case 1:
                scanForDevices()
            case 2:
                connectToDevice()
            case 3:
                disconnectFromDevice()
            case 4:
                exit(0)
            default:
                print("Invalid choice. Please try again.")
                processUserInput()
            }
        } else {
            print("Invalid input. Please enter a number.")
            processUserInput()
        }
    }

    func scanForDevices() {
        print("Scanning for devices for \(scanDuration) seconds...")
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + scanDuration) {
            self.centralManager?.stopScan()
            self.connectToDevice()
        }
    }

    func connectToDevice() {
        print("Enter the keyword to search for in the device ID:")
        guard let keyword = readLine() else {
            print("Invalid input.")
            return
        }
        let filteredDevices = devices.filter { $0.identifier.uuidString.contains(keyword) }
        if filteredDevices.isEmpty {
            print("No devices found matching the keyword.")
            return
        }
        print("Select a device to connect:")
        for (index, device) in filteredDevices.enumerated() {
            print("\(index + 1). \(device.name ?? "Unknown") (\(device.identifier.uuidString))")
        }
        if let choice = readLine(), let index = Int(choice), index > 0, index <= filteredDevices.count {
            let selectedDevice = filteredDevices[index - 1]
            print("Connecting to \(selectedDevice.name ?? "Unknown") (\(selectedDevice.identifier.uuidString))...")
            centralManager?.connect(selectedDevice, options: nil)
        } else {
            print("Invalid choice.")
        }
    }

    func disconnectFromDevice() {
        if let connectedDevice = connectedDevice {
            centralManager?.cancelPeripheralConnection(connectedDevice)
            print("Disconnected from device.")
        } else {
            print("Not currently connected to any device.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name, !discoveredDeviceUUIDs.contains(peripheral.identifier) {
            print("Found device: \(name), ID: \(peripheral.identifier.uuidString)")
            devices.append(peripheral)
            discoveredDeviceUUIDs.insert(peripheral.identifier)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to device: \(peripheral.name ?? "Unknown"), ID: \(peripheral.identifier.uuidString)")
        connectedDevice = peripheral
        processUserInput()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to device: \(peripheral.name ?? "Unknown"), ID: \(peripheral.identifier.uuidString)")
        processUserInput()
    }
}

func main() {
    let scanner = BluetoothScanner()
    RunLoop.main.run()
}

main()
