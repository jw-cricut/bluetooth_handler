import Foundation

// MARK: - C-compatible bridges for C++

@_cdecl("StartBLEScan")
public func StartBLEScan() {
    print("StartBLEScan() called from C++")
    let scanner = BluetoothScanner()
    scanner.startScan()
}

@_cdecl("StartBLEScanAndReturnJSON")
public func StartBLEScanAndReturnJSON() -> UnsafePointer<CChar>? {
    let scanner = BluetoothScanner()
    let results = scanner.startScanSync()

    do {
        let jsonData = try JSONSerialization.data(withJSONObject: results, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8)!

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
    let scanner = BluetoothScanner()
    scanner.connectToDevice(with: uuidString)
}

