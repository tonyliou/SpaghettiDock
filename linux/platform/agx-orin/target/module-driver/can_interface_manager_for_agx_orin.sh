#!/bin/bash

# Function to print menu
print_menu() {
    echo "========== Jetson AGX Orin CAN Configuration Script =========="
    echo "1. Check CAN driver and interface status"
    echo "2. Install dependencies (busybox, can-utils)"
    echo "3. Load necessary kernel modules"
    echo "4. Configure Pinmux registers for SFIO (CAN mode)"
    echo "5. Enable CAN0 interface"
    echo "6. Enable CAN1 interface"
    echo "7. Enable VCAN0 interface (virtual CAN)"
    echo "8. Enable VCAN1 interface (virtual CAN)"
    echo "9. Disable CAN0 interface"
    echo "10. Disable CAN1 interface"
    echo "11. Disable VCAN0 interface"
    echo "12. Disable VCAN1 interface"
    echo "13. Test CAN transmission and reception"
    echo "14. Exit"
    echo "=============================================================="
}

# Function to check CAN driver and interface status
check_status() {
    echo "Checking kernel module status..."
    lsmod | grep -q "mttcan" && echo "mttcan module is loaded" || echo "mttcan module is not loaded"

    echo "Checking network interfaces..."
    ip link show | grep -q "can" && echo "CAN interface is available" || echo "CAN interface is not enabled"
}

# Function to install dependencies
install_dependencies() {
    echo "Installing required packages (busybox, can-utils)..."
    sudo apt update && sudo apt install -y busybox can-utils
    if [[ $? -eq 0 ]]; then
        echo "Dependencies installed successfully."
    else
        echo "Failed to install dependencies."
    fi
}

# Function to load kernel modules
load_modules() {
    echo "Loading necessary kernel modules..."
    sudo modprobe can
    sudo modprobe can_raw
    sudo modprobe mttcan
    sudo modprobe vcan  # Virtual CAN for testing
    if lsmod | grep -q "mttcan"; then
        echo "Kernel modules loaded successfully."
    else
        echo "Failed to load kernel modules. Please check your system configuration."
    fi
}

# Function to configure pins for SFIO mode
configure_pins() {
    echo "Configuring pins for SFIO mode (CAN functionality)..."
    sudo busybox devmem 0x0c303018 32 0xc458  # CAN0_DIN
    sudo busybox devmem 0x0c303010 32 0xc400  # CAN0_DOUT
    sudo busybox devmem 0x0c303008 32 0xc458  # CAN1_DIN
    sudo busybox devmem 0x0c303000 32 0xc400  # CAN1_DOUT
    echo "Pin configuration completed!"
}

# Function to set up CAN or VCAN interface
setup_can_interface() {
    local interface=$1
    local bitrate=$2

    if [[ $interface == vcan* ]]; then
        sudo ip link add dev $interface type vcan
    fi

    sudo ip link set $interface up type can bitrate $bitrate
    if [[ $? -eq 0 ]]; then
        echo "$interface is up with bitrate $bitrate bps."
    else
        echo "Failed to set up $interface."
    fi
}

# Function to disable CAN or VCAN interface
disable_can_interface() {
    local interface=$1

    sudo ip link set $interface down
    if [[ $? -eq 0 ]]; then
        echo "$interface is down."
    else
        echo "Failed to bring down $interface."
    fi

    if [[ $interface == vcan* ]]; then
        sudo ip link delete $interface
    fi
}

# Function to test CAN transmission and reception
test_can() {
    echo "Please select test mode:"
    echo "1. Receive data (candump)"
    echo "2. Send data (cansend)"
    read -r choice

    case $choice in
        1)
            echo "Select CAN interface (can0, can1, vcan0, or vcan1):"
            read -r can_num
            echo "Starting data reception... Press Ctrl+C to stop."
            candump $can_num
            ;;
        2)
            echo "Select CAN interface (can0, can1, vcan0, or vcan1):"
            read -r can_num
            echo "Enter the CAN frame to send (format: ID#DATA, e.g., 123#11223344):"
            read -r frame
            echo "Sending CAN frame: $frame"
            cansend $can_num $frame
            ;;
        *)
            echo "Invalid selection"
            ;;
    esac
}

# Main script loop
while true; do
    print_menu
    echo "Please select an option (enter a number):"
    read -r option

    case $option in
        1) check_status ;;
        2) install_dependencies ;;
        3) load_modules ;;
        4) configure_pins ;;
        5) 
            read -p "Enter bitrate for CAN0 (e.g., 500000): " bitrate
            setup_can_interface can0 $bitrate
            ;;
        6)
            read -p "Enter bitrate for CAN1 (e.g., 500000): " bitrate
            setup_can_interface can1 $bitrate
            ;;
        7) setup_can_interface vcan0 0 ;;
        8) setup_can_interface vcan1 0 ;;
        9) disable_can_interface can0 ;;
        10) disable_can_interface can1 ;;
        11) disable_can_interface vcan0 ;;
        12) disable_can_interface vcan1 ;;
        13) test_can ;;
        14) echo "Exiting script."; break ;;
        *) echo "Invalid option. Please enter a valid number." ;;
    esac
    echo ""
done