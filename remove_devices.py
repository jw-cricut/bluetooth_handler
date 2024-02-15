import subprocess

def get_paired_devices():
    try:
        output = subprocess.check_output(['bluetoothctl', 'paired-devices'], text=True)
        return [line.split(' ', 2)[2].strip() for line in output.split('\n') if 'Device' in line]
    except subprocess.CalledProcessError:
        print("Error retrieving paired devices.")
        return []

def unpair_and_delete(device_name):
    try:
        subprocess.run(['bluetoothctl', 'remove', device_name], check=True)
        print(f"Unpaired and deleted device: {device_name}")
    except subprocess.CalledProcessError:
        print(f"Error unpairing and deleting device: {device_name}")

def main():
    keywords_file = 'keywords.txt'  #path to .txt file containing keywords

    try:
        with open(keywords_file, 'r') as file:
            keywords = [line.strip() for line in file.readlines()]
    except FileNotFoundError:
        print(f"File not found: {keywords_file}")
        return

    paired_devices = get_paired_devices()

    for device_name in paired_devices:
        if any(keyword in device_name for keyword in keywords):
            unpair_and_delete(device_name)

if __name__ == "__main__":
    main()
