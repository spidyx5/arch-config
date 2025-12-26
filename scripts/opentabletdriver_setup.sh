#!/bin/bash

echo "=== Setting up OpenTabletDriver ==="

# 1. Rebuild Initramfs (Root)
# Required if you modified modprobe files or blacklists recently
echo "Rebuilding Initramfs..."
sudo mkinitcpio -P

# 2. Reload Udev Rules (Root)
# Necessary for the system to recognize the tablet permissions immediately
echo "Reloading Udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

# 3. Enable Systemd Service (User)
# Note: This runs as the current user (do NOT use sudo here)
echo "Enabling OpenTabletDriver user service..."
systemctl --user daemon-reload
systemctl --user enable --now opentabletdriver.service

# 4. Status Check
if systemctl --user is-active --quiet opentabletdriver.service; then
    echo "SUCCESS: OpenTabletDriver daemon is running."
else
    echo "WARNING: OpenTabletDriver daemon failed to start. Check 'systemctl --user status opentabletdriver.service'"
fi
