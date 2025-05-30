#include "BTClassicScan.h"
#import "BluetoothScannerBridge.h"

#include "DeviceInfo.h"
#include <nlohmann/json.hpp>

#include <string>
#include <vector>
#include <iostream>

using json = nlohmann::json;

void BTClassicScan::startScan() {
    NSLog(@"[macOS] Using CoreBluetooth (Swift) via bridge...");
    StartBLEScan();
}

std::vector<DeviceInfo> BTClassicScan::startScanAndReturnDevices() {
    std::vector<DeviceInfo> results;

    const char* rawJson = StartBLEScanAndReturnJSON();
    if (!rawJson) {
        std::cerr << "Swift BLE scan returned null JSON." << std::endl;
        return results;
    }

    // Use unique_ptr with custom deleter to safely free strdup'ed or malloc'ed string
    std::unique_ptr<char, decltype(&free)> jsonStr(const_cast<char*>(rawJson), &free);

    try {
        auto parsed = nlohmann::json::parse(jsonStr.get());

        for (const auto& item : parsed) {
            DeviceInfo device;
            device.BTFriendlyName = item.value("name", "");
            device.comPortName = item.value("uuid", ""); // Optional: replace with actual COM port if applicable
            device.interfaceType = BT;
            device.interfaceIndex = static_cast<int>(results.size());
            device.machineType = UNKNOWN_MECH_TYPE;

            results.push_back(device);
        }
    } catch (const std::exception& e) {
        std::cerr << "Failed to parse BLE JSON: " << e.what() << std::endl;
    }

    return results;
}

