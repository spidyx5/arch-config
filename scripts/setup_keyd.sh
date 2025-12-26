#!/bin/bash

# Check if keyd is installed
if ! command -v keyd &> /dev/null; then
    echo "Error: keyd is not installed. Please install it first."
    exit 1
fi

echo "=== Setting up Keyd (Colemak-DH + Gaming Mode) ==="

CONF="/etc/keyd/default.conf"

# 1. Create Config Directory
sudo mkdir -p /etc/keyd

# 2. Write the Configuration
echo "Writing $CONF..."
cat <<EOF | sudo tee $CONF
[ids]
*

[main]
# 1. Base Layout: Colemak-DH
# Note: Ensure /usr/share/keyd/layouts/colemak_dh exists, otherwise use explicit mapping.
include layouts/colemak_dh

# 2. Modifiers
# CapsLock -> Escape (Tap) / Control (Hold) - (More common for Vim/Devs)
# change 'escape' to 'backspace' if you prefer your original setting.
capslock = overload(control, backspace)

# 3. Toggle Gaming Mode
# Using 'control+shift+space' prevents conflicts with standard 'control+space'
control+shift+space = toggle(gaming)

[gaming]
# Reset all keys to QWERTY mappings, overriding the [main] Colemak include
include layouts/qwerty

# Keep the CapsLock behavior in gaming mode
capslock = overload(control, backspace)

# Allow switching BACK to Colemak
control+shift+space = toggle(gaming)
EOF

# 3. Reload Service
echo "Reloading Keyd..."
sudo systemctl enable --now keyd
sudo keyd reload

echo "----------------------------------------------------"
echo "Setup Complete."
echo "Default: Colemak-DH"
echo "Gaming Toggle: Press 'Ctrl + Shift + Space'"
echo "----------------------------------------------------"