#!/usr/bin/env bash
#
# jetson_kernel_customization_menu.sh
#
# Demonstrates a Jetson kernel customization script with:
#   - Installing prerequisites (build-essential, bc, git-core)
#   - Git-based kernel source sync
#   - Separate extraction steps for kernel tarballs and toolchain
#   - Color-coded console output
#   - "Clean" step for kernel
#   - Optional "enable" for RT kernel during in-tree kernel build
#   - Optional IGNORE_PREEMPT_RT_PRESENCE=1 for OOT modules
#   - Building and installing kernel (in-tree & OOT modules)
#   - Updating initramfs
#   - Building & installing DTBs
#   - CROSS_COMPILE as a prefix (checking ${CROSS_COMPILE}gcc)
#

set -e  # Exit on error
set -u  # Exit on uninitialized variable

###############################################################################
# (A) CONFIGURATION
###############################################################################

INSTALL_PATH="$HOME/nvidia/nvidia_sdk/JetPack_6.1_Linux_JETSON_AGX_ORIN_TARGETS"

TOOLCHAIN_BASE_DIR="$HOME/l4t-gcc"
TOOLCHAIN_SUBDIR="aarch64--glibc--stable-2022.08-1"

# CROSS_COMPILE is a prefix, e.g.: /.../bin/aarch64-buildroot-linux-gnu-
CROSS_COMPILE="$TOOLCHAIN_BASE_DIR/$TOOLCHAIN_SUBDIR/bin/aarch64-buildroot-linux-gnu-"

RELEASE_TAG="jetson_36.4"

# Location of manually downloaded tarballs (kernel tarballs + toolchain tarball)
SOURCE_ARCHIVE_DIR="$HOME/kernel_tarballs"

# Kernel tarball filenames
KERNEL_TARBALLS=(
  "public_sources.tbz2"
  "kernel_src.tbz2"
  "kernel_oot_modules_src.tbz2"
  "nvidia_kernel_display_driver_source.tbz2"
)

# Toolchain tarball name
TOOLCHAIN_TARBALL="aarch64--glibc--stable-2022.08-1.tar.bz2"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'  # No Color

###############################################################################
# (B) HELPER: Colorful echo wrappers
###############################################################################
info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

###############################################################################
# (B.1) Check cross-compiler
###############################################################################
test_cross_compiler() {
  if [[ -x "${CROSS_COMPILE}gcc" ]]; then
    success "Cross-compiler found: ${CROSS_COMPILE}gcc"
  else
    error "Cross-compiler not found: ${CROSS_COMPILE}gcc"
    return 1
  fi
}

###############################################################################
# (1) Install prerequisites
###############################################################################
install_prerequisites() {
  info "=== [1] Installing prerequisites ==="
  sudo apt update
  sudo apt install -y build-essential bc git-core
  success "Prerequisites installed (build-essential, bc, git-core)."
}

###############################################################################
# (2) Test path availability
###############################################################################
test_paths() {
  info "=== [2] Testing path and file accessibility ==="

  if [[ ! -d "$INSTALL_PATH" ]]; then
    error "INSTALL_PATH=$INSTALL_PATH does not exist or is not accessible."
    return 1
  fi
  if [[ ! -d "$INSTALL_PATH/Linux_for_Tegra" ]]; then
    warn "Could not find Linux_for_Tegra under $INSTALL_PATH. Please verify."
  fi

  local CROSS_BIN_DIR
  CROSS_BIN_DIR="$(dirname "${CROSS_COMPILE}gcc")"
  if [[ ! -d "$CROSS_BIN_DIR" ]]; then
    warn "Toolchain bin dir not found: $CROSS_BIN_DIR (may need extraction)."
  fi

  if [[ ! -d "$SOURCE_ARCHIVE_DIR" ]]; then
    warn "SOURCE_ARCHIVE_DIR=$SOURCE_ARCHIVE_DIR not found or inaccessible."
  fi

  success "Path testing completed."
}

###############################################################################
# (3) Sync/Download Kernel Sources (using source_sync.sh)
###############################################################################
sync_kernel_sources() {
  info "=== [3] Sync/Download Kernel Source (Git sync) ==="
  pushd "$INSTALL_PATH/Linux_for_Tegra/source" >/dev/null 2>&1
    if [[ -f "./source_sync.sh" ]]; then
      info "Running: ./source_sync.sh -k -t $RELEASE_TAG"
      ./source_sync.sh -k -t "$RELEASE_TAG"
      success "Sync/Download completed."
    else
      error "source_sync.sh not found in $(pwd). Please verify your environment."
    fi
  popd >/dev/null 2>&1
}

###############################################################################
# (4) Extract Kernel Tarballs
###############################################################################
extract_kernel_sources() {
  info "=== [4] Extracting Kernel Tarballs ==="

  local kernel_dir="$INSTALL_PATH/Linux_for_Tegra/source/kernel/kernel-jammy-src"
  if [[ -d "$kernel_dir" ]]; then
    warn "Kernel folder already exists at: $kernel_dir"
    warn "Skipping kernel source extraction."
    return
  fi

  pushd "$INSTALL_PATH/Linux_for_Tegra/source" >/dev/null 2>&1

  for tarball in "${KERNEL_TARBALLS[@]}"; do
    local tar_path="$SOURCE_ARCHIVE_DIR/$tarball"
    if [[ -f "$tar_path" ]]; then
      info "Extracting $tarball ..."
      if [[ "$tarball" == "public_sources.tbz2" ]]; then
        tar xf "$tar_path" -C "$INSTALL_PATH/Linux_for_Tegra/.."
      else
        tar xf "$tar_path"
      fi
    else
      warn "$tarball not found in $SOURCE_ARCHIVE_DIR (skipping)."
    fi
  done

  popd >/dev/null 2>&1
  success "Kernel sources extraction done."
}

###############################################################################
# (5) Extract Toolchain
###############################################################################
extract_toolchain() {
  info "=== [5] Extracting Toolchain from $SOURCE_ARCHIVE_DIR ==="

  local toolchain_archive="$SOURCE_ARCHIVE_DIR/$TOOLCHAIN_TARBALL"
  local toolchain_target_dir="$TOOLCHAIN_BASE_DIR/$TOOLCHAIN_SUBDIR"

  if [[ -d "$toolchain_target_dir" ]]; then
    warn "Toolchain directory already exists at: $toolchain_target_dir"
    warn "Skipping extraction (remove/rename if you want fresh extract)."
    return
  fi

  if [[ ! -f "$toolchain_archive" ]]; then
    error "Toolchain tarball not found: $toolchain_archive"
    return 1
  fi

  mkdir -p "$TOOLCHAIN_BASE_DIR"
  pushd "$TOOLCHAIN_BASE_DIR" >/dev/null 2>&1
    info "Extracting toolchain: $TOOLCHAIN_TARBALL -> $(pwd)"
    tar xf "$toolchain_archive"
  popd >/dev/null 2>&1

  success "Toolchain extracted into: $toolchain_target_dir"
}

###############################################################################
# (6) Clean Kernel build directory
###############################################################################
clean_kernel() {
  info "=== [6] Cleaning Kernel build directory (make clean) ==="
  pushd "$INSTALL_PATH/Linux_for_Tegra/source" >/dev/null 2>&1
    if [[ -d kernel ]]; then
      make -C kernel clean
      success "Kernel build directory cleaned."
    else
      warn "No 'kernel' directory in $(pwd). Nothing to clean."
    fi
  popd >/dev/null 2>&1
}

###############################################################################
# (7) Build the Kernel (in-tree modules) with optional RT
###############################################################################
build_kernel() {
  info "=== [7] Building the Kernel (in-tree modules) ==="

  test_cross_compiler || return 1

  pushd "$INSTALL_PATH/Linux_for_Tegra/source" >/dev/null 2>&1
    # Ask if user wants to enable Real-time kernel
    if [[ -f "./generic_rt_build.sh" ]]; then
      read -rp "Would you like to enable Real-time kernel? (y/N): " rt_ans
      if [[ "$rt_ans" =~ ^[Yy]$ ]]; then
        info "Enabling RT kernel via ./generic_rt_build.sh \"enable\"..."
        ./generic_rt_build.sh "enable"
      else
        warn "Skipping RT kernel enable."
      fi
    else
      warn "generic_rt_build.sh not found, skipping RT enable step."
    fi

    export CROSS_COMPILE="$CROSS_COMPILE"
    info "Running: make -C kernel"
    make -C kernel
    success "Kernel build completed."
  popd >/dev/null 2>&1
}

###############################################################################
# (8) Install the Kernel and in-tree modules
###############################################################################
install_kernel() {
  info "=== [8] Installing Kernel (in-tree modules) ==="
  pushd "$INSTALL_PATH/Linux_for_Tegra/source" >/dev/null 2>&1
    export INSTALL_MOD_PATH="${INSTALL_PATH}/Linux_for_Tegra/rootfs/"
    sudo -E make install -C kernel

    cp kernel/kernel-jammy-src/arch/arm64/boot/Image \
       "${INSTALL_PATH}/Linux_for_Tegra/kernel/Image"

    success "Kernel and in-tree modules installed."
  popd >/dev/null 2>&1
}

###############################################################################
# (9) Build Out-of-Tree Modules (with optional IGNORE_PREEMPT_RT_PRESENCE=1)
###############################################################################
build_oot_modules() {
  info "=== [9] Building Out-of-Tree Modules ==="
  test_cross_compiler || return 1

  pushd "$INSTALL_PATH/Linux_for_Tegra/source" >/dev/null 2>&1

    # Ask if user wants to set IGNORE_PREEMPT_RT_PRESENCE=1
    read -rp "Building for RT kernel? Export IGNORE_PREEMPT_RT_PRESENCE=1? (y/N): " ignore_rt
    if [[ "$ignore_rt" =~ ^[Yy]$ ]]; then
      info "Exporting IGNORE_PREEMPT_RT_PRESENCE=1"
      export IGNORE_PREEMPT_RT_PRESENCE=1
    else
      warn "Skipping IGNORE_PREEMPT_RT_PRESENCE=1"
    fi

    export CROSS_COMPILE="$CROSS_COMPILE"
    export KERNEL_HEADERS="$PWD/kernel/kernel-jammy-src"
    make modules
    success "Out-of-Tree Modules built."
  popd >/dev/null 2>&1
}

###############################################################################
# (10) Install Out-of-Tree Modules
###############################################################################
install_oot_modules() {
  info "=== [10] Installing Out-of-Tree Modules ==="
  pushd "$INSTALL_PATH/Linux_for_Tegra/source" >/dev/null 2>&1
    export INSTALL_MOD_PATH="${INSTALL_PATH}/Linux_for_Tegra/rootfs/"
    sudo -E make modules_install
    success "Out-of-Tree Modules installed."
  popd >/dev/null 2>&1
}

###############################################################################
# (11) Update initramfs
###############################################################################
update_initramfs() {
  info "=== [11] Updating initramfs ==="
  pushd "$INSTALL_PATH/Linux_for_Tegra" >/dev/null 2>&1
    if [[ -x ./tools/l4t_update_initrd.sh ]]; then
      sudo ./tools/l4t_update_initrd.sh
      success "initramfs updated."
    else
      warn "l4t_update_initrd.sh not found in ./tools. Skipping."
    fi
  popd >/dev/null 2>&1
}

###############################################################################
# (12) Build and install DTBs
###############################################################################
build_and_install_dtbs() {
  info "=== [12] Building and installing DTBs ==="
  test_cross_compiler || return 1

  pushd "$INSTALL_PATH/Linux_for_Tegra/source" >/dev/null 2>&1
    export CROSS_COMPILE="$CROSS_COMPILE"
    export KERNEL_HEADERS="$PWD/kernel/kernel-jammy-src"
    make dtbs
    cp kernel-devicetree/generic-dts/dtbs/* \
       "${INSTALL_PATH}/Linux_for_Tegra/kernel/dtb/"
    success "DTBs built and installed."
  popd >/dev/null 2>&1
}

###############################################################################
# (13) Flash Jetson AGX Orin
###############################################################################
flash_agx_orin() {
  info "=== [13] Flashing Jetson AGX Orin Devkit ==="
  pushd "$INSTALL_PATH/Linux_for_Tegra" >/dev/null 2>&1
  if [[ -x ./flash.sh ]]; then
    info "Flashing Jetson AGX Orin Devkit (internal storage)..."
    sudo ./flash.sh jetson-agx-orin-devkit internal
    success "Flashing completed. Please reboot the device."
  else
    error "flash.sh not found in $INSTALL_PATH/Linux_for_Tegra. Please verify the environment."
  fi
  popd >/dev/null 2>&1
}

###############################################################################
# Interactive Menu
###############################################################################
run_menu() {
  while true; do
    echo ""
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN} Jetson Kernel Customization Menu${NC}"
    echo -e "${GREEN}=============================================${NC}"
    echo " 1) Install prerequisites (build-essential, bc, git-core)"
    echo " 2) Test path accessibility"
    echo " 3) Sync/Download Kernel Sources (Git)"
    echo " 4) Extract Kernel Tarballs"
    echo " 5) Extract Toolchain"
    echo " 6) Clean Kernel build directory"
    echo " 7) Build Kernel (in-tree) [Optional RT]"
    echo " 8) Install Kernel (in-tree)"
    echo " 9) Build Out-of-Tree Modules [Optional IGNORE_PREEMPT_RT_PRESENCE=1]"
    echo "10) Install Out-of-Tree Modules"
    echo "11) Update initramfs"
    echo "12) Build & Install DTBs"
	echo "13) Flash Jetson AGX Orin Devkit (internal storage)"
    echo " 0) Exit"
    echo -e "${GREEN}=============================================${NC}"
    read -rp "Please enter your choice: " choice
    echo ""

    case "$choice" in
      1)  install_prerequisites ;;
      2)  test_paths ;;
      3)  sync_kernel_sources ;;
      4)  extract_kernel_sources ;;
      5)  extract_toolchain ;;
      6)  clean_kernel ;;
      7)  build_kernel ;;
      8)  install_kernel ;;
      9)  build_oot_modules ;;
      10) install_oot_modules ;;
      11) update_initramfs ;;
      12) build_and_install_dtbs ;;
	  13) flash_agx_orin ;;

      0)
          info "Exiting script."
          exit 0
          ;;
      *)
          warn "Invalid selection, please try again."
          ;;
    esac
  done
}

###############################################################################
# Main Entry Point
###############################################################################
run_menu