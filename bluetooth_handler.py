import sys
import asyncio
from PyQt6.QtCore import Qt, QThread, pyqtSignal
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel, QPushButton, QListWidget, QLineEdit, QDialog

import bleak
from bleak import BleakClient

class BluetoothWorkerThread(QThread):
    devices_discovered = pyqtSignal(list)

    def __init__(self):
        super().__init__()
        self.keyword = None

    def run(self):
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        devices = loop.run_until_complete(self.discover_ble_devices())
        self.devices_discovered.emit(devices)

    async def discover_ble_devices(self):
        devices = await bleak.BleakScanner.discover()
        return devices

    def set_keyword(self, keyword):
        self.keyword = keyword

    def get_keyword(self):
        return self.keyword

    def stop(self):
        self.quit()

class BluetoothSettingsDialog(QDialog):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Advanced Bluetooth Settings")
        self.setGeometry(200, 200, 400, 300)

        self.device_list = QListWidget(self)
        self.keyword_input = QLineEdit(self)
        self.keyword_input.setPlaceholderText("Enter Keyword")

        self.info_label = QLabel(self)
        self.info_label.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.refresh_button = QPushButton("Refresh Devices", self)
        self.refresh_button.clicked.connect(self.refresh_device_list)

        self.add_button = QPushButton("Connect to Device", self)
        self.add_button.clicked.connect(self.connect_device)

        self.remove_button = QPushButton("Remove Selected Device", self)
        self.remove_button.clicked.connect(self.remove_selected_device)

        layout = QVBoxLayout(self)
        layout.addWidget(QLabel("Discovered BLE Devices:"))
        layout.addWidget(self.device_list)
        layout.addWidget(QLabel("Filter Devices by Keyword:"))
        layout.addWidget(self.keyword_input)
        layout.addWidget(self.info_label)
        layout.addWidget(self.refresh_button)
        layout.addWidget(self.add_button)
        layout.addWidget(self.remove_button)

        self.worker_thread = BluetoothWorkerThread()
        self.worker_thread.devices_discovered.connect(self.display_discovered_devices)

    def refresh_device_list(self):
        keyword = self.keyword_input.text().strip().lower()
        self.device_list.clear()
        self.info_label.clear()
        self.worker_thread.set_keyword(keyword)
        self.worker_thread.start()

    def display_discovered_devices(self, devices):
        keyword = self.worker_thread.get_keyword()

        if not keyword:
            # Display all devices if no keyword is entered
            for device in devices:
                if device.name:
                    self.device_list.addItem(f"Device Name: {device.name}, Address: {device.address}")
            self.info_label.setText(f"Found {len(devices)} BLE devices.")
        else:
            # Filter devices based on the entered keyword
            filtered_devices = [device for device in devices if device.name and keyword in device.name.lower()]
            for device in filtered_devices:
                self.device_list.addItem(f"Device Name: {device.name}, Address: {device.address}")
            self.info_label.setText(f"Found {len(filtered_devices)} BLE devices matching '{keyword}'.")

    def connect_device(self):
        selected_item = self.device_list.currentItem()
        if selected_item:
            device_address = selected_item.text().split(" ")[-1]
            print(f"Connecting to/pairing with device: {device_address}")
            asyncio.run(self.add_device(device_address))


    async def add_device(self, device_address):
         # Add logic for connecting/pairing with the selected device here
        print(f"Adding device {device_address}...")
        # Simulate a delay to represent the async operation
        async with BleakClient(device_address) as client: 
            await client.connect(timeout=30)
        print(f"Device {device_address} added successfully.")
        pass

    def remove_selected_device(self):
        selected_item = self.device_list.currentItem()
        if selected_item:
            device_info = selected_item.text()
            # Implement logic for removing a device here
            # Extract the device information from the selected item
            # and use it to remove the corresponding device
            self.info_label.setText(f"Removed device: {device_info}")
            self.device_list.takeItem(self.device_list.row(selected_item))

    def closeEvent(self, event):
        self.worker_thread.stop()
        event.accept()

class BluetoothManager(QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Bluetooth Manager")
        self.setGeometry(100, 100, 400, 300)

        self.advanced_settings_button = QPushButton("Advanced Bluetooth Settings", self)
        self.advanced_settings_button.clicked.connect(self.show_advanced_settings)

        self.dialog = None  # Instance variable to store the BluetoothSettingsDialog instance

        layout = QVBoxLayout(self)
        layout.addWidget(self.advanced_settings_button)

    def show_advanced_settings(self):
        self.dialog = BluetoothSettingsDialog()
        self.dialog.exec()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = BluetoothManager()
    window.show()
    sys.exit(app.exec())