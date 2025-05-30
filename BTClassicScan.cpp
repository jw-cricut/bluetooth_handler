#include "BTClassicScan.h"
#include <iostream>

#if defined(_WIN32) || defined(_WIN64)

// Windows implementation
#include <Windows.h>
#include <BluetoothAPIs.h>
#pragma comment(lib, "BluetoothAPIs.lib")

void BTClassicScan::startScan() {
    BLUETOOTH_DEVICE_SEARCH_PARAMS searchParams = { sizeof(BLUETOOTH_DEVICE_SEARCH_PARAMS) };
    searchParams.fReturnAuthenticated = TRUE;
    searchParams.fReturnRemembered = TRUE;
    searchParams.fReturnUnknown = TRUE;
    searchParams.fReturnConnected = TRUE;
    searchParams.fIssueInquiry = TRUE;
    searchParams.cTimeoutMultiplier = 15;

    BLUETOOTH_DEVICE_INFO deviceInfo = { sizeof(BLUETOOTH_DEVICE_INFO) };
    HBLUETOOTH_DEVICE_FIND hDeviceFind = BluetoothFindFirstDevice(&searchParams, &deviceInfo);

    if (hDeviceFind != NULL) {
        do {
            std::wcout << L"Bluetooth device found: " << deviceInfo.szName
                       << L" - " << deviceInfo.Address.ullLong << std::endl;
        } while (BluetoothFindNextDevice(hDeviceFind, &deviceInfo));

        BluetoothFindDeviceClose(hDeviceFind);
    } else {
        std::cout << "No Bluetooth devices found or Bluetooth not available." << std::endl;
    }
}

#elif defined(__linux__)

// Linux (BlueZ) implementation
#include <bluetooth/bluetooth.h>
#include <bluetooth/hci.h>
#include <bluetooth/hci_lib.h>
#include <unistd.h>

void BTClassicScan::startScan() {
    inquiry_info *ii = nullptr;
    int max_rsp = 255;
    int num_rsp;
    int dev_id, sock, len, flags;

    dev_id = hci_get_route(nullptr);
    sock = hci_open_dev(dev_id);
    if (dev_id < 0 || sock < 0) {
        std::cerr << "Bluetooth not available or no adapter found." << std::endl;
        return;
    }

    len = 8; // ~10.24 seconds
    flags = IREQ_CACHE_FLUSH;
    ii = (inquiry_info*)malloc(max_rsp * sizeof(inquiry_info));

    num_rsp = hci_inquiry(dev_id, len, max_rsp, nullptr, &ii, flags);
    if (num_rsp < 0) {
        perror("hci_inquiry");
        free(ii);
        return;
    }

    char addr[19] = { 0 };
    for (int i = 0; i < num_rsp; i++) {
        ba2str(&(ii+i)->bdaddr, addr);
        std::cout << "Bluetooth device found: " << addr << std::endl;
    }

    free(ii);
    close(sock);
}

#elif defined(__APPLE__)

// macOS stub implementation
void BTClassicScan::startScan() {
    std::cout << "[macOS] Bluetooth Classic scanning is not supported via public APIs." << std::endl;
    std::cout << "Consider using CoreBluetooth for BLE devices." << std::endl;
}

#else
void BTClassicScan::startScan() {
    std::cerr << "Unsupported platform." << std::endl;
}
#endif

