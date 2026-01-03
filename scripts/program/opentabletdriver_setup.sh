#!/bin/bash

# ==============================================================================
# SPIDY OPENTABLETDRIVER SETUP
# ==============================================================================

# 1. Ensure Root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (sudo)"
    exit 1
fi

# 2. Detect the Real User (who ran sudo)
REAL_USER=${SUDO_USER:-$USER}
USER_ID=$(id -u "$REAL_USER")
EXPORT_SOCK="/run/user/$USER_ID"

echo "=== 🖊️ Setting up OpenTabletDriver for $REAL_USER ==="

# ==============================================================================
# STEP 1: KERNEL & DRIVER UPDATES
# ==============================================================================
echo "[-] Step 1: Rebuilding Initramfs (mkinitcpio)..."
# This blocks conflicting drivers (like wacom)
mkinitcpio -P

echo "[-] Step 2: Reloading USB Rules..."
udevadm control --reload-rules
udevadm trigger

# ==============================================================================
# STEP 2: DAEMON PREPARATION (The requested step)
# ==============================================================================
echo "[-] Step 3: Checking otd-daemon..."

# Check if the command actually exists
if ! command -v otd-daemon &> /dev/null; then
    echo "    ❌ Error: otd-daemon command not found!"
    echo "       Please install: paru -S opentabletdriver"
    exit 1
fi

# IMPORTANT: We do NOT run 'otd-daemon' here directly because it would freeze the script.
# Instead, we kill any existing manual instances so systemd can take over cleanly.
echo "    -> Cleaning up old daemon instances..."
pkill -x otd-daemon || true

# ==============================================================================
# STEP 3: STARTING THE SERVICE
# ==============================================================================
echo "[-] Step 4: Enabling & Starting OTD Service..."

# This command essentially runs 'otd-daemon' in the background for you
if [ -d "$EXPORT_SOCK" ]; then
    sudo -u "$REAL_USER" XDG_RUNTIME_DIR="$EXPORT_SOCK" systemctl --user enable --now opentabletdriver.service
    echo "    ✅ Service Started (Daemon is running)."
else
    echo "    ⚠️ User session not found. Service will start on next Reboot."
    systemctl --global enable opentabletdriver.service
fi

echo "=== ✅ Setup Complete ==="
echo "If your tablet doesn't work immediately, unplug it and plug it back in."