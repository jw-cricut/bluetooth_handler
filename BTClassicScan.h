#pragma once
#import "BluetoothScannerBridge.h"
#import "DeviceInfo.h"
#include <vector>

class BTClassicScan {
public:
    static void startScan();
    static std::vector<DeviceInfo> startScanAndReturnDevices();
};

