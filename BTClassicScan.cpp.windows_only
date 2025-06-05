#include <iostream>
#include <vector>
#include <Windows.h>
#include <BluetoothAPIs.h>

#pragma comment(lib, "BluetoothAPIs.lib")

// Function to discover nearby Bluetooth devices
void DiscoverBluetoothDevices() {
    BLUETOOTH_DEVICE_SEARCH_PARAMS searchParams = { sizeof(BLUETOOTH_DEVICE_SEARCH_PARAMS) };
    searchParams.fReturnAuthenticated = TRUE;
    searchParams.fReturnRemembered = TRUE;
    searchParams.fReturnUnknown = TRUE;
    searchParams.fReturnConnected = TRUE;
    searchParams.fIssueInquiry = TRUE;
    searchParams.cTimeoutMultiplier = 15; // Timeout for scanning in multiples of 1.28 seconds

    BLUETOOTH_DEVICE_INFO deviceInfo = { sizeof(BLUETOOTH_DEVICE_INFO) };
    HBLUETOOTH_DEVICE_FIND hDeviceFind = BluetoothFindFirstDevice(&searchParams, &deviceInfo);

    if (hDeviceFind != NULL) {
        do {
            // Print device name and UUID
            std::wcout << "Bluetooth device found: " << deviceInfo.szName << " - " << deviceInfo.Address.ullLong << std::endl;

            // Continue searching for more devices
        } while (BluetoothFindNextDevice(hDeviceFind, &deviceInfo));

        BluetoothFindDeviceClose(hDeviceFind);
    }
}

int main() {
    std::cout << "Scanning for Bluetooth devices..." << std::endl;

    DiscoverBluetoothDevices();

    return 0;
}
