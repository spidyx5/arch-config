#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

echo "=== Setting up OpenTabletDriver ==="

# ==============================================================================
# 1. SYSTEM CONFIGURATION (Root)
# ==============================================================================
echo "Step 1: Rebuilding Initramfs..."
# Required to apply any modprobe blacklists included with the driver
mkinitcpio -P

echo "Step 2: Reloading Udev rules..."
# Required for the system to recognize the tablet USB device
udevadm control --reload-rules
udevadm trigger

# ==============================================================================
# 2. SERVICE CONFIGURATION
# ==============================================================================
echo "Step 3: Enabling OpenTabletDriver Service..."

# FIXED: Use --global enable
# This enables the user service for ALL users on the system.
# It avoids the "$DBUS_SESSION_BUS_ADDRESS" error completely.
systemctl --global enable opentabletdriver.service

echo " -> Service enabled globally."

# ==============================================================================
# 3. ATTEMPT IMMEDIATE START (Optional)
# ==============================================================================
# We try to start it for the user who ran sudo, but we don't crash if it fails.
REAL_USER=${SUDO_USER:-$USER}
USER_ID=$(id -u "$REAL_USER")
EXPORT_SOCK="/run/user/$USER_ID"

if [ -d "$EXPORT_SOCK" ]; then
    echo " -> Attempting to start service for $REAL_USER..."
    # We manually inject the environment variable needed for systemctl --user to work
    if sudo -u "$REAL_USER" XDG_RUNTIME_DIR="$EXPORT_SOCK" systemctl --user start opentabletdriver.service 2>/dev/null; then
        echo " -> SUCCESS: Service started."
    else
        echo " -> NOTE: Could not start immediately. It will start automatically on Reboot."
    fi
else
    echo " -> NOTE: User session not found. Service will start on next Reboot."
fi

echo "=== Setup Complete ==="