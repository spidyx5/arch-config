#!/bin/bash

echo "=== Setting up Keyd (Colemak-DH + Gaming Mode) ==="

# 1. Create the Config Directory
sudo mkdir -p /etc/keyd

# 2. Write the Configuration
echo "Writing /etc/keyd/default.conf..."
cat <<EOF | sudo tee /etc/keyd/default.conf
[ids]
*

[main]
# 1. Use built-in Colemak-DH layout
include layouts/colemak_dh

# 2. Modifiers
# Capslock acts as Backspace when tapped, Control when held
capslock = overload(control, backspace)

# 3. Toggle for Gaming (Switch to QWERTY)
# Press Control + Space to toggle the 'gaming' layer
control+space = toggle(gaming)

[gaming]
# This layer resets keys to standard QWERTY
include layouts/qwerty

# Keep the Capslock behavior in gaming mode (optional, remove if you want standard capslock)
capslock = overload(control, backspace)

# Allow switching BACK to Colemak from Gaming mode
control+space = toggle(gaming)
EOF

# 3. Enable and Reload Service
echo "Enabling Keyd service..."
sudo systemctl enable --now keyd
sudo systemctl restart keyd

echo "Keyd setup complete."
echo "Layout: Colemak-DH (Default)"
echo "Toggle: Press 'Ctrl + Space' to switch between Colemak and QWERTY."
