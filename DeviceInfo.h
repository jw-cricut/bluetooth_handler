#pragma once

#include <string>
#include "phosg/JSON.hh"

// Enum for different interface types
enum InterfaceType {
    USB,
    USB_HID,
    BT,
    UNKNOWN_INTERFACE
};

// Enum for machine types — expand as needed
enum MachineType {
    UNKNOWN_MECH_TYPE = 0,
    MECH_TYPE_A,
    MECH_TYPE_B,
    // Add more here
};

struct DeviceInfo {
    std::string comPortName;
    std::string BTFriendlyName;
    InterfaceType interfaceType;
    int interfaceIndex;
    MachineType machineType;

    // Convert DeviceInfo -> JSON
    phosg::JSON to_json() const {
        return phosg::JSON::dict({
            {"comPortName", comPortName},
            {"BTFriendlyName", BTFriendlyName},
            {"interfaceType", static_cast<int64_t>(interfaceType)},
            {"interfaceIndex", interfaceIndex},
            {"machineType", static_cast<int64_t>(machineType)}
        });
    }

    // Convert JSON -> DeviceInfo
    static DeviceInfo from_json(const phosg::JSON& json) {
        DeviceInfo device;
        device.comPortName = json.get_string("comPortName", "");
        device.BTFriendlyName = json.get_string("BTFriendlyName", "");
        device.interfaceType = static_cast<InterfaceType>(json.get_int("interfaceType", UNKNOWN_INTERFACE));
        device.interfaceIndex = static_cast<int>(json.get_int("interfaceIndex", 0));
        device.machineType = static_cast<MachineType>(json.get_int("machineType", UNKNOWN_MECH_TYPE));
        return device;
    }
};

