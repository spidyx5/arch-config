#!/bin/bash
# Master Setup Script
# Location: /arch-config/scripts/master_setup.sh

set -e  # Exit immediately if any script fails

# 1. Check if running as Root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run with sudo."
    echo "Usage: sudo ./master_setup.sh"
    exit 1
fi

# 2. Detect the Real User (to run user-config scripts correctly)
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# 3. Set the Script Directory
# This ensures it works no matter where you run the command from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== 🚀 Starting Master Arch Setup ==="
echo "📂 Script Directory: $SCRIPT_DIR"
echo "👤 Configuring for User: $REAL_USER ($USER_HOME)"
echo ""

# ==============================================================================
# PHASE 1: REPOSITORIES (CRITICAL FIRST STEP)
# ==============================================================================
echo "📦 [1/5] Setting up Repositories..."
# We must do this first so subsequent scripts can find packages
bash "$SCRIPT_DIR/chaotic-repo.sh"
bash "$SCRIPT_DIR/cachy-repo.sh"

# Refresh pacman to see new packages
pacman -Sy

# ==============================================================================
# PHASE 2: SYSTEM CONFIGURATION (ROOT)
# ==============================================================================
echo "⚙️ [2/5] Running System & Hardware Setup..."

# Optimization first
#bash "$SCRIPT_DIR/optimize_makepkg.sh"

# Hardware & Drivers
bash "$SCRIPT_DIR/setup_hardware.sh"
bash "$SCRIPT_DIR/setup_keyd.sh"
bash "$SCRIPT_DIR/setup_audio.sh"

# Virtualization (needs to add groups)
bash "$SCRIPT_DIR/setup_virt.sh"

# General System Config & Services
bash "$SCRIPT_DIR/apply_system_config.sh"
bash "$SCRIPT_DIR/setup_services.sh"
bash "$SCRIPT_DIR/setup_wayland_config.sh"
bash "$SCRIPT_DIR/setup_network.sh"

# ==============================================================================
# PHASE 3: KERNEL & BOOTLOADER
# ==============================================================================
echo "🐧 [3/5] Installing Kernels & Bootloader..."


# 2. Update Bootloader (Must run AFTER kernels are installed)
bash "$SCRIPT_DIR/update_limine.sh"

# ==============================================================================
# PHASE 4: USER CONFIGURATIONS (RUN AS USER)
# ==============================================================================
echo "🎨 [4/5] Applying User Configurations..."
echo "   (Dropping root privileges to run as $REAL_USER)"

# Helper function to run script as the real user
run_as_user() {
    sudo -u "$REAL_USER" bash "$1"
}

# XDG Dirs (Documents, Downloads, etc.)
run_as_user "$SCRIPT_DIR/setup_xdg.sh"

# Terminal Configs
run_as_user "$SCRIPT_DIR/setup_terminal.sh"

# Tablet Driver Config (creates user config files)
run_as_user "$SCRIPT_DIR/opentabletdriver_setup.sh"

# ==============================================================================
# PHASE 5: COMPLETION
# ==============================================================================
echo ""
echo "✅ Master setup complete!"
echo "   Please Reboot your system to apply all changes."