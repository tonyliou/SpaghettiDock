#!/bin/bash

# Function to install dependencies
install_dependencies() {
  echo "Installing required packages..."
  sudo apt update && sudo apt install -y can-utils
  if [[ $? -eq 0 ]]; then
    echo "Dependencies installed successfully."
  else
    echo "Failed to install dependencies."
  fi
}

# Function to load required modules
load_modules() {
  echo "Loading necessary kernel modules..."
  sudo modprobe can
  sudo modprobe can_raw
  sudo modprobe can_bcm
  sudo modprobe vcan

  if lsmod | grep -q "can" && lsmod | grep -q "vcan"; then
    echo "Kernel modules loaded successfully."
  else
    echo "Failed to load kernel modules. Please check your system configuration."
  fi
}

# Function to enable CAN interface
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

# Function to disable CAN interface
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

# Display menu
display_menu() {
  echo "Choose an option:"
  echo "1) Install dependencies"
  echo "2) Load necessary kernel modules"
  echo "3) Enable CAN0"
  echo "4) Enable CAN1"
  echo "5) Enable VCAN0"
  echo "6) Enable VCAN1"
  echo "7) Disable CAN0"
  echo "8) Disable CAN1"
  echo "9) Disable VCAN0"
  echo "10) Disable VCAN1"
  echo "11) Exit"
  read -p "Enter your choice: " choice
  echo ""
}

# Main script loop
while true; do
  display_menu

  case $choice in
    1)
      install_dependencies
      ;;
    2)
      load_modules
      ;;
    3)
      read -p "Enter bitrate for CAN0 (e.g., 500000): " bitrate
      setup_can_interface can0 $bitrate
      ;;
    4)
      read -p "Enter bitrate for CAN1 (e.g., 500000): " bitrate
      setup_can_interface can1 $bitrate
      ;;
    5)
      setup_can_interface vcan0 0
      ;;
    6)
      setup_can_interface vcan1 0
      ;;
    7)
      disable_can_interface can0
      ;;
    8)
      disable_can_interface can1
      ;;
    9)
      disable_can_interface vcan0
      ;;
    10)
      disable_can_interface vcan1
      ;;
    11)
      echo "Exiting."
      break
      ;;
    *)
      echo "Invalid choice. Please try again."
      ;;
  esac
  echo ""
done