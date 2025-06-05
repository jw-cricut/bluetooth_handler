import Foundation

// MARK: - C-compatible bridges for C++

public typealias BLEConnectionCallback = @convention(c) (UnsafePointer<CChar>) -> Void

// This must be global and public so it’s accessible from Swift and C++
public var connectionCallback: BLEConnectionCallback?

// Shared instance of BluetoothScanner to persist state and CBCentralManager
private let sharedScanner = BluetoothScanner()

@_cdecl("StartBLEScan")
public func StartBLEScan() {
    print("StartBLEScan() called from C++")
    sharedScanner.startScan()
}

@_cdecl("StartBLEScanAndReturnJSON")
public func StartBLEScanAndReturnJSON() -> UnsafePointer<CChar>? {
    let results = sharedScanner.startScanSync()

    do {
        let jsonData = try JSONSerialization.data(withJSONObject: results, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""

        let cString = strdup(jsonString)
        return UnsafePointer(cString)
    } catch {
        print("Failed to serialize device list: \(error)")
        return nil
    }
}

@_cdecl("ConnectToBLEDevice")
public func ConnectToBLEDevice(_ uuidCString: UnsafePointer<CChar>) {
    let uuidString = String(cString: uuidCString)
    print("ConnectToBLEDevice called from C++ with UUID: \(uuidString)")
    sharedScanner.connectToDevice(with: uuidString)
}

@_cdecl("RegisterBLEConnectionCallback")
public func RegisterBLEConnectionCallback(_ callback: @escaping BLEConnectionCallback) {
    print("Registering BLE connection callback from C++...")
    connectionCallback = callback
}

@_cdecl("DisconnectFromBLEDevice")
public func DisconnectFromBLEDevice() {
    print("DisconnectFromBLEDevice() called from C++")
    sharedScanner.disconnect()
}