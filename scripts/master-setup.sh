#!/bin/bash
# Master setup script

set -e  # Exit on any error

# 1. Check for Sudo
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo"
    echo "Usage: sudo $0"
    exit 1
fi

# 2. Get the Real User (for non-root scripts)
REAL_USER=${SUDO_USER:-$USER}

# 3. Define Directories Correctly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Assuming the second batch of scripts is inside a 'scripts' subdirectory:
SUB_DIR="$SCRIPT_DIR/scripts"

echo "=== Starting Master Setup Script ==="
echo "Running as root. User configurations will apply to: $REAL_USER"
echo ""

# ==============================================================================
# PHASE 1: REPOSITORIES (Must be first so packages can be found)
# ==============================================================================
echo "📦 Setting up Repositories..."
# Using "$SUB_DIR" ensures it finds the file regardless of where you run the script from
bash "$SUB_DIR/chaotic-repo.sh"
bash "$SUB_DIR/cachy-repo.sh"

# Update pacman databases after adding repos
pacman -Sy

# ==============================================================================
# PHASE 2: SYSTEM CONFIG (Root level)
# ==============================================================================
echo "📦 Running system setup scripts..."
bash "$SCRIPT_DIR/setup_hardware.sh"
bash "$SCRIPT_DIR/setup_keyd.sh"
bash "$SCRIPT_DIR/optimize_makepkg.sh"
bash "$SCRIPT_DIR/apply_system_config.sh"
bash "$SCRIPT_DIR/setup_services.sh"
bash "$SCRIPT_DIR/setup_audio.sh"
bash "$SCRIPT_DIR/setup_wayland_config.sh"

# ==============================================================================
# PHASE 3: KERNELS & BOOTLOADER (Order matters!)
# ==============================================================================
echo "📦 Installing Kernels..."
bash "$SCRIPT_DIR/install_kernels.sh"

echo "📦 Updating Bootloader (Limine)..."
# Must run AFTER kernels are installed
bash "$SCRIPT_DIR/update_limine.sh"

# ==============================================================================
# PHASE 4: USER PROGRAMS (Drop privileges for these!)
# ==============================================================================
echo "📦 Running user-level program setups..."

# We use 'sudo -u $REAL_USER' to run these as your actual user, not root.
# This prevents permission issues in your home directory.

echo " -> Configuring XDG (User)..."
sudo -u "$REAL_USER" bash "$SCRIPT_DIR/setup_xdg.sh"

echo " -> Configuring Tablet Driver..."
# Assuming this needs to access user config:
sudo -u "$REAL_USER" bash "$SUB_DIR/opentabletdriver_setup.sh"

echo " -> Configuring Browser..."
sudo -u "$REAL_USER" bash "$SUB_DIR/browser_config.sh"

echo " -> Configuring Terminal..."
sudo -u "$REAL_USER" bash "$SUB_DIR/setup_terminal.sh"

# ==============================================================================
# PHASE 5: VIRTUALIZATION & FINALIZATION
# ==============================================================================
echo "📦 Running virtualization setup..."
bash "$SUB_DIR/setup_virt.sh"

echo ""
echo "✅ Master setup script completed successfully!"