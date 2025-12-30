#!/bin/bash

# Check if keyd is installed
if ! command -v keyd &> /dev/null; then
    echo "Error: keyd is not installed. Please install it first."
    exit 1
fi

echo "=== Setting up Keyd (Colemak-DH Angle-Z + Gaming Mode) ==="

CONF="/etc/keyd/default.conf"

# 1. Create Config Directory
sudo mkdir -p /etc/keyd

# 2. Write the Configuration
echo "Writing configuration to $CONF..."
cat <<EOF | sudo tee $CONF
[ids]
*

[main]
# --- Toggle Logic ---
# Press Ctrl + Alt + Space to toggle the 'qwerty' layer for gaming
C-A-space = toggle(qwerty)

# --- Colemak-DH (ANSI Angle-Z Mod) ---

# Row 1 (QWERTY q-p) -> qwfpbjluy;
q = q
w = w
e = f
r = p
t = b
y = j
u = l
i = u
o = y
p = semicolon

# Row 2 (QWERTY a-;) -> arstgmneio
a = a
s = r
d = s
f = t
g = g
h = m
j = n
k = e
l = i
semicolon = o

# Row 3 (QWERTY z-/) -> xcdvzkh,./
# This uses the "Angle Mod" which shifts zxcv to the left and moves Z to the middle
z = x
x = c
c = d
v = v
b = z
n = k
m = h

# Standard Colemak Mod: Map CapsLock to Backspace
#capslock = backspace

# --- Gaming Layer (QWERTY) ---
# This layer restores keys to their physical default when toggled on
[qwerty]
# Toggle back to Colemak (Main) using the same combo
C-A-space = toggle(qwerty)

# Reset ALL modified keys back to default QWERTY
e = e
r = r
t = t
y = y
u = u
i = i
o = o
p = p
s = s
d = d
f = f
h = h
j = j
k = k
l = l
semicolon = semicolon
z = z
x = x
c = c
v = v
b = b
n = n
m = m
capslock = capslock
EOF

# 3. Reload Keyd
echo "Reloading Keyd..."
sudo systemctl enable --now keyd
sudo keyd reload

echo "----------------------------------------------------"
echo "Setup Complete."
echo "Active Layout: Colemak-DH (Angle Mod)"
echo "Gaming Toggle: Press <Ctrl> + <Alt> + <Space> to switch to QWERTY"
