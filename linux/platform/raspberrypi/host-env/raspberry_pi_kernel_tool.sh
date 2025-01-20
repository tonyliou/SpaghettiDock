#!/bin/bash

# Function to display menu
show_menu() {
  echo "=========================="
  echo " Raspberry Pi Kernel Script "
  echo "=========================="
  echo "Please select an option:"
  echo "1. Install dependencies"
  echo "2. Download kernel source"
  echo "3. Configure kernel (Native Build)"
  echo "4. Configure kernel (Cross-Compilation)"
  echo "5. Customize kernel with menuconfig"
  echo "6. Build kernel"
  echo "7. Install kernel"
  echo "8. Exit"
  echo -n "Enter your choice: "
}

# Install dependencies
install_dependencies() {
  echo "Installing dependencies..."
  sudo apt update && sudo apt install -y git bc bison flex libssl-dev make libc6-dev libncurses5-dev
  echo "Dependencies installed."
}

# Download kernel source
download_kernel_source() {
  echo "Downloading Raspberry Pi kernel source..."
  echo "Do you want to clone the entire repository or just the latest branch? (Enter 1 for latest, 2 for full history)"
  read choice
  if [ "$choice" -eq 1 ]; then
    git clone --depth=1 https://github.com/raspberrypi/linux
  else
    git clone https://github.com/raspberrypi/linux
  fi
  echo "Kernel source downloaded."
}

# Configure kernel for native builds
configure_kernel_native() {
  cd linux || exit
  echo "Select your Raspberry Pi model (1 to 6):"
  echo "1. Raspberry Pi 3 (64-bit kernel)"
  echo "2. Raspberry Pi 4/400/Zero 2 W (32-bit kernel)"
  echo "3. Raspberry Pi 1 (32-bit kernel)"
  echo "4. Raspberry Pi 2/3/4 (32-bit kernel)"
  echo "5. Raspberry Pi 5 (64-bit kernel)"
  echo "6. Pi 500 or Compute Module 5 (64-bit kernel)"
  echo -n "Enter your choice: "
  read model_choice
  case $model_choice in
    1) KERNEL=kernel8; make bcm2711_defconfig;;
    2) KERNEL=kernel7l; make bcm2711_defconfig;;
    3) KERNEL=kernel; make bcmrpi_defconfig;;
    4) KERNEL=kernel7; make bcm2709_defconfig;;
    5) KERNEL=kernel_2712; make bcm2712_defconfig;;
    6) KERNEL=kernel_2712; make bcm2712_defconfig;;
    *) echo "Invalid option!"; exit 1;;
  esac
  echo "Kernel configuration set for native build."
}

# Configure kernel for cross-compilation
configure_kernel_cross_compile() {
  cd linux || exit
  echo "Select architecture (1 for 64-bit, 2 for 32-bit):"
  read arch_choice
  if [ "$arch_choice" -eq 1 ]; then
    sudo apt install -y crossbuild-essential-arm64
    echo "Select Raspberry Pi model:"
    echo "1. Raspberry Pi 3"
    echo "2. Raspberry Pi 4/400/Zero 2 W"
    echo "3. Raspberry Pi 5"
    echo "4. Pi 500 or Compute Module 5"
    read model_choice
    case $model_choice in
      1) KERNEL=kernel8; make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig;;
      2) KERNEL=kernel8; make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig;;
      3) KERNEL=kernel_2712; make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2712_defconfig;;
      4) KERNEL=kernel_2712; make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2712_defconfig;;
      *) echo "Invalid option!"; exit 1;;
    esac
  else
    sudo apt install -y crossbuild-essential-armhf
    echo "Select Raspberry Pi model (32-bit options):"
    echo "1. Raspberry Pi 1"
    echo "2. Raspberry Pi 2/3/4"
    read model_choice
    case $model_choice in
      1) KERNEL=kernel; make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcmrpi_defconfig;;
      2) KERNEL=kernel7; make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig;;
      *) echo "Invalid option!"; exit 1;;
    esac
  fi
  echo "Kernel configuration set for cross-compilation."
}

# Customize kernel using menuconfig
customize_menuconfig() {
  echo "Launching menuconfig interface..."
  make menuconfig
  echo "Configuration complete."
}

# Build kernel
build_kernel() {
  echo "Building kernel..."
  echo "Select build type (1 for 64-bit, 2 for 32-bit):"
  read build_choice
  if [ "$build_choice" -eq 1 ]; then
    make -j$(nproc) Image.gz modules dtbs
  else
    make -j$(nproc) zImage modules dtbs
  fi
  echo "Kernel build complete."
}

# Install kernel
install_kernel() {
  echo "Installing kernel..."
  echo "Select installation type (1 for native system, 2 for external media):"
  read install_type
  if [ "$install_type" -eq 1 ]; then
    sudo make modules_install
    sudo cp /boot/firmware/$KERNEL.img /boot/firmware/$KERNEL-backup.img
    if [ "$build_choice" -eq 1 ]; then
      sudo cp arch/arm64/boot/Image.gz /boot/firmware/$KERNEL.img
      sudo cp arch/arm64/boot/dts/broadcom/*.dtb /boot/firmware/
      sudo cp arch/arm64/boot/dts/overlays/*.dtb* /boot/firmware/overlays/
      sudo cp arch/arm64/boot/dts/overlays/README /boot/firmware/overlays/
    else
      sudo cp arch/arm/boot/zImage /boot/firmware/$KERNEL.img
      sudo cp arch/arm/boot/dts/*.dtb /boot/firmware/
      sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/firmware/overlays/
      sudo cp arch/arm/boot/dts/overlays/README /boot/firmware/overlays/
    fi
  else
    echo "Please enter the mount point for your boot media (e.g., /dev/sdb1 for boot and /dev/sdb2 for root):"
    read boot_media
    sudo mkdir -p mnt/boot mnt/root
    sudo mount /dev/${boot_media}1 mnt/boot
    sudo mount /dev/${boot_media}2 mnt/root
    sudo env PATH=$PATH make INSTALL_MOD_PATH=mnt/root modules_install
    sudo cp mnt/boot/$KERNEL.img mnt/boot/$KERNEL-backup.img
    sudo cp arch/arm64/boot/Image.gz mnt/boot/$KERNEL.img
    sudo cp arch/arm64/boot/dts/broadcom/*.dtb mnt/boot/
    sudo cp arch/arm64/boot/dts/overlays/*.dtb* mnt/boot/overlays/
    sudo cp arch/arm64/boot/dts/overlays/README mnt/boot/overlays/
    sudo umount mnt/boot
    sudo umount mnt/root
  fi
  echo "Kernel installed. Rebooting now..."
  sudo reboot
}

# Main menu loop
while true; do
  show_menu
  read choice
  case $choice in
    1) install_dependencies;;
    2) download_kernel_source;;
    3) configure_kernel_native;;
    4) configure_kernel_cross_compile;;
    5) customize_menuconfig;;
    6) build_kernel;;
    7) install_kernel;;
    8) echo "Exiting."; exit;;
    *) echo "Invalid option. Please try again.";;
  esac
done
