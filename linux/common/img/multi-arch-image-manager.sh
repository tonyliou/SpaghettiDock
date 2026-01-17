#!/bin/bash
# Multi-Architecture Image Maintenance Script
# Set Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

MOUNT_POINT="/mnt/image_root"
IMAGE_FILE=""
LOOP_DEV=""
IMAGE_ARCH=""
QEMU_BINARY=""

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Please run this script with sudo${NC}"
   exit 1
fi

show_menu() {
    echo -e "\n${YELLOW}╔════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║   Multi-Arch Image Maintenance Menu (2026) ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════╝${NC}"
    if [ ! -z "$IMAGE_FILE" ]; then
        echo -e "${BLUE}📁 Current Image: ${IMAGE_FILE}${NC}"
        echo -e "${BLUE}🖥️  Architecture: ${IMAGE_ARCH:-Not Selected}${NC}"
    fi
    echo "1) Initialize Environment (Install QEMU)"
    echo "2) Select and Mount Image"
    echo "3) Enter Environment (Chroot)"
    echo "4) Safe Unmount and Cleanup"
    echo "5) 🔥 Force Cleanup All Loop Devices"
    echo "6) Exit"
    echo -n "Please select [1-6]: "
}

init_env() {
    echo -e "${YELLOW}Installing required packages...${NC}"
    apt update && apt install -y kpartx qemu-user-static binfmt-support docker.io
    
    # Fix WSL2 binfmt issues
    echo -e "${YELLOW}Registering QEMU binfmt...${NC}"
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    
    echo -e "${GREEN}✓ Environment initialization complete${NC}"
    echo -e "${CYAN}Installed QEMU emulators:${NC}"
    ls -1 /usr/bin/qemu-*-static 2>/dev/null | sed 's|/usr/bin/||' || echo "  No emulators found"
}

# Select Architecture
select_architecture() {
    echo -e "\n${CYAN}╔════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Select Image Architecture      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════╝${NC}"
    echo "1) x86_64 (AMD64)          - Standard PC/Server"
    echo "2) aarch64 (ARM64)         - Raspberry Pi 4/5, Apple Silicon"
    echo "3) armv7l (ARM 32-bit)     - Raspberry Pi 2/3"
    echo "4) riscv64 (RISC-V 64)     - RISC-V Dev Boards"
    echo "5) i386 (x86 32-bit)       - Legacy PC"
    echo "6) mips64el                - MIPS Architecture"
    echo "7) ppc64le (PowerPC)       - IBM Power"
    echo "8) s390x                   - IBM z/Architecture"
    echo -n "Select [1-8]: "
    
    read arch_choice
    
    case $arch_choice in
        1)
            IMAGE_ARCH="x86_64"
            QEMU_BINARY="qemu-x86_64-static"
            ;;
        2)
            IMAGE_ARCH="aarch64"
            QEMU_BINARY="qemu-aarch64-static"
            ;;
        3)
            IMAGE_ARCH="armv7l"
            QEMU_BINARY="qemu-arm-static"
            ;;
        4)
            IMAGE_ARCH="riscv64"
            QEMU_BINARY="qemu-riscv64-static"
            ;;
        5)
            IMAGE_ARCH="i386"
            QEMU_BINARY="qemu-i386-static"
            ;;
        6)
            IMAGE_ARCH="mips64el"
            QEMU_BINARY="qemu-mips64el-static"
            ;;
        7)
            IMAGE_ARCH="ppc64le"
            QEMU_BINARY="qemu-ppc64le-static"
            ;;
        8)
            IMAGE_ARCH="s390x"
            QEMU_BINARY="qemu-s390x-static"
            ;;
        *)
            echo -e "${RED}Invalid selection, defaulting to x86_64${NC}"
            IMAGE_ARCH="x86_64"
            QEMU_BINARY="qemu-x86_64-static"
            ;;
    esac
    
    echo -e "${GREEN}✓ Selected Architecture: ${IMAGE_ARCH}${NC}"
    return 0
}

# Search and Pick File
select_image_file() {
    echo -e "${CYAN}Scanning directory for .img files...${NC}"
    
    shopt -s nullglob
    files=(*.img)
    shopt -u nullglob
    
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}Error: No .img files found in current directory!${NC}"
        return 1
    fi
    
    echo "Please select a file to mount:"
    for i in "${!files[@]}"; do
        echo "$((i+1))) ${files[$i]}"
    done
    echo "q) Cancel"
    read -p "Enter number: " choice
    
    if [[ "$choice" == "q" ]]; then return 1; fi
    
    if [[ "$choice" -gt 0 && "$choice" -le "${#files[@]}" ]]; then
        IMAGE_FILE="${files[$((choice-1))]}"
        echo -e "${GREEN}Selected: $IMAGE_FILE${NC}"
        
        # Select Architecture
        select_architecture
        return 0
    else
        echo -e "${RED}Invalid choice!${NC}"
        return 1
    fi
}

mount_img() {
    if ! select_image_file; then return; fi
    
    echo -e "${YELLOW}Creating partition mappings...${NC}"
    kpartx -d "$IMAGE_FILE" 2>/dev/null || true
    
    KPARTX_OUT=$(kpartx -av "$IMAGE_FILE")
    echo "$KPARTX_OUT"
    
    # Parse loop device name correctly
    LOOP_DEV=$(echo "$KPARTX_OUT" | awk '/add map/{print $3}' | head -n 1 | sed 's/p[0-9]*$//')
    
    if [ -z "$LOOP_DEV" ]; then
        echo -e "${RED}Mapping failed. Please check if the image is corrupted.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Detected loop device: $LOOP_DEV${NC}"
    mkdir -p "$MOUNT_POINT"
    
    # Mount Root Partition
    echo -e "${YELLOW}Mounting Root Partition (/dev/mapper/${LOOP_DEV}p2)...${NC}"
    if ! mount "/dev/mapper/${LOOP_DEV}p2" "$MOUNT_POINT"; then
        echo -e "${RED}Root partition mount failed!${NC}"
        kpartx -d "$IMAGE_FILE"
        return 1
    fi
    
    # Mount Boot Partition
    if [ -d "$MOUNT_POINT/boot/firmware" ]; then
        echo "Detected /boot/firmware path"
        mount "/dev/mapper/${LOOP_DEV}p1" "$MOUNT_POINT/boot/firmware" 2>/dev/null || echo -e "${YELLOW}Boot mount failed (Non-critical)${NC}"
    elif [ -d "$MOUNT_POINT/boot" ]; then
        mount "/dev/mapper/${LOOP_DEV}p1" "$MOUNT_POINT/boot" 2>/dev/null || echo -e "${YELLOW}Boot mount failed (Non-critical)${NC}"
    fi
    
    # Configure QEMU Emulator
    HOST_ARCH=$(uname -m)
    
    if [ "$HOST_ARCH" != "$IMAGE_ARCH" ]; then
        echo -e "${CYAN}Configuring cross-arch emulator (${IMAGE_ARCH})...${NC}"
        
        if [ -f "/usr/bin/$QEMU_BINARY" ]; then
            cp "/usr/bin/$QEMU_BINARY" "$MOUNT_POINT/usr/bin/"
            echo -e "${GREEN}✓ Copied $QEMU_BINARY${NC}"
        else
            echo -e "${RED}⚠️ Error: Could not find $QEMU_BINARY${NC}"
            echo -e "${YELLOW}Please run option 1 to install QEMU emulators first${NC}"
            cleanup
            return 1
        fi
    else
        echo -e "${GREEN}✓ Native architecture ($HOST_ARCH), no emulator needed${NC}"
    fi
    
    # Configure DNS
    cp /etc/resolv.conf "$MOUNT_POINT/etc/resolv.conf" 2>/dev/null
    
    echo -e "${YELLOW}Binding virtual system directories...${NC}"
    for i in /dev /dev/pts /proc /sys /run; do
        if [ -d "$i" ]; then
            mount --bind $i "$MOUNT_POINT$i" || echo -e "${YELLOW}Warning: $i mount failed${NC}"
        fi
    done
    
    echo -e "${GREEN}╔════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║ ✓ Mount Success! Use option 3 to enter ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════╝${NC}"
}

enter_chroot() {
    if ! mountpoint -q "$MOUNT_POINT"; then
        echo -e "${RED}Error: Image not mounted!${NC}"
        return
    fi
    
    echo -e "${MAGENTA}╔════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║  Entering ${IMAGE_ARCH} Environment${NC}"
    echo -e "${MAGENTA}║  Type ${YELLOW}exit${MAGENTA} to return to host    ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════╝${NC}"
    
    # Set environment variables for better chroot experience
    export PS1="(chroot-${IMAGE_ARCH}) \u@\h:\w\$ "
    
    chroot "$MOUNT_POINT" /bin/bash --login
    
    echo -e "${GREEN}Exited chroot environment${NC}"
}

cleanup() {
    echo -e "${YELLOW}╔════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Starting Cleanup (5 Steps)    ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════╝${NC}"
    
    # === Step 1: Sync I/O ===
    echo -e "${CYAN}[1/5] Syncing disk buffers...${NC}"
    sync
    sleep 1
    
    # === Step 2: Unmount bind mounts ===
    echo -e "${CYAN}[2/5] Unmounting virtual filesystems...${NC}"
    for mp in /run /sys /proc /dev/pts /dev; do
        if mountpoint -q "$MOUNT_POINT$mp" 2>/dev/null; then
            echo "   ⤷ Unmounting $MOUNT_POINT$mp"
            umount "$MOUNT_POINT$mp" 2>/dev/null || umount -l "$MOUNT_POINT$mp" 2>/dev/null
        fi
    done
    
    # === Step 3: Unmount boot and root ===
    echo -e "${CYAN}[3/5] Unmounting image partitions...${NC}"
    if mountpoint -q "$MOUNT_POINT/boot/firmware" 2>/dev/null; then
        umount "$MOUNT_POINT/boot/firmware" 2>/dev/null || umount -l "$MOUNT_POINT/boot/firmware"
    fi
    if mountpoint -q "$MOUNT_POINT/boot" 2>/dev/null; then
        umount "$MOUNT_POINT/boot" 2>/dev/null || umount -l "$MOUNT_POINT/boot"
    fi
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        umount "$MOUNT_POINT" 2>/dev/null || umount -l "$MOUNT_POINT"
    fi
    
    sync
    sleep 1
    
    # === Step 4: Remove device-mapper ===
    echo -e "${CYAN}[4/5] Cleaning device-mapper...${NC}"
    if [ ! -z "$LOOP_DEV" ]; then
        for part in $(dmsetup ls 2>/dev/null | grep "^${LOOP_DEV}p" | awk '{print $1}'); do
            echo "   ⤷ Removing $part"
            dmsetup remove "$part" 2>/dev/null || dmsetup remove -f "$part" 2>/dev/null
        done
    fi
    
    # === Step 5: Cleanup loop devices ===
    echo -e "${CYAN}[5/5] Deleting loop devices...${NC}"
    if [ ! -z "$IMAGE_FILE" ] && [ -f "$IMAGE_FILE" ]; then
        kpartx -d "$IMAGE_FILE" 2>/dev/null
        
        LOOP_LIST=$(losetup -j "$IMAGE_FILE" 2>/dev/null | cut -d ':' -f1)
        for loop in $LOOP_LIST; do
            echo "   ⤷ Deleting $loop"
            losetup -d "$loop" 2>/dev/null
        done
        
        echo -e "${GREEN}✓ Fully cleaned: $IMAGE_FILE${NC}"
    else
        echo -e "${YELLOW}⚠ IMAGE_FILE not set, performing global cleanup${NC}"
        dmsetup ls 2>/dev/null | grep "^loop" | awk '{print $1}' | while read dev; do
            dmsetup remove -f "$dev" 2>/dev/null
        done
        losetup -D 2>/dev/null
    fi
    
    # Verify
    REMAIN_LOOP=$(losetup -a 2>/dev/null | wc -l)
    REMAIN_DM=$(dmsetup ls 2>/dev/null | grep "^loop" | wc -l)
    
    if [ "$REMAIN_LOOP" -eq 0 ] && [ "$REMAIN_DM" -eq 0 ]; then
        echo -e "${GREEN}✓ Cleanup complete, no residual devices${NC}"
    else
        echo -e "${RED}⚠ Warning: $REMAIN_LOOP loop devices and $REMAIN_DM mapper devices remain${NC}"
        echo -e "${YELLOW}Try option 5 for force cleanup${NC}"
    fi
    
    IMAGE_FILE=""
    LOOP_DEV=""
    IMAGE_ARCH=""
    QEMU_BINARY=""
}

force_cleanup() {
    echo -e "${RED}╔════════════════════════════════════╗${NC}"
    echo -e "${RED}║      ⚠️  FORCE CLEANUP WARNING      ║${NC}"
    echo -e "${RED}║ This will delete ALL loop devices! ║${NC}"
    echo -e "${RED}╚════════════════════════════════════╝${NC}"
    read -p "Are you sure? (yes/N): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo "Cancelled"
        return
    fi
    
    echo -e "${YELLOW}Executing force cleanup...${NC}"
    
    # 1. Force unmount everything at mount point
    grep "$MOUNT_POINT" /proc/mounts 2>/dev/null | cut -d ' ' -f2 | sort -r | xargs -r umount -lf 2>/dev/null
    
    # 2. Delete all loop-related device-mappers
    echo "Cleaning device-mapper..."
    dmsetup remove_all -f 2>/dev/null
    
    # 3. Delete all loop devices
    echo "Cleaning loop devices..."
    losetup -D 2>/dev/null
    
    # 4. Verify
    sleep 1
    REMAIN=$(losetup -a 2>/dev/null | wc -l)
    if [ "$REMAIN" -eq 0 ]; then
        echo -e "${GREEN}✓ All loop devices cleared${NC}"
    else
        echo -e "${RED}⚠ $REMAIN devices remain${NC}"
        echo -e "${YELLOW}Suggest rebooting for a clean slate${NC}"
    fi
    
    IMAGE_FILE=""
    LOOP_DEV=""
    IMAGE_ARCH=""
    QEMU_BINARY=""
}

# Main Loop
while true; do
    show_menu
    read sel
    case $sel in
        1) init_env ;;
        2) mount_img ;;
        3) enter_chroot ;;
        4) cleanup ;;
        5) force_cleanup ;;
        6) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid Selection${NC}" ;;
    esac
done
