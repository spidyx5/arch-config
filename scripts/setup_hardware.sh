#!/bin/bash

# Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit
fi

# Detect the actual user who ran sudo
REAL_USER=${SUDO_USER:-$USER}

echo "=== ⚙️ Configuring Hardware, Power & RAM (Spidy Profile) ==="

# ==============================================================================
# 1. ENVIRONMENT VARIABLES (Drivers & RAM Optimization)
# ==============================================================================
echo "[-] Configuring Environment Variables..."

# 1. Intel Media Driver (Your Tweak)
# Checks if it exists to avoid duplicates
if ! grep -q "LIBVA_DRIVER_NAME=iHD" /etc/environment; then
    echo "LIBVA_DRIVER_NAME=iHD" | tee -a /etc/environment
    echo " -> Added iHD driver variable."
fi

# 2. MALLOC_ARENA_MAX (Improvement for Low RAM)
# This forces glibc to be aggressive about returning memory to the OS.
if ! grep -q "MALLOC_ARENA_MAX=2" /etc/environment; then
    echo "MALLOC_ARENA_MAX=2" | tee -a /etc/environment
    echo " -> Added MALLOC_ARENA_MAX=2 (RAM Saver)."
fi

# Ensure the actual driver is installed
if pacman -Qi intel-media-driver &> /dev/null; then
    echo " -> intel-media-driver is already installed."
else
    echo " -> Installing intel-media-driver (required for iHD)..."
    pacman -S --noconfirm intel-media-driver
fi


# ==============================================================================
# 2. POWER MANAGEMENT (Sleep & Logind)
# ==============================================================================
echo "[-] Configuring Sleep & Logind..."

# Sleep Config (Your Tweak)
cat <<EOF | tee /etc/systemd/sleep.conf
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
SuspendState=mem
AllowSuspendThenHibernate=no
AllowHybridSleep=yes
EOF

# Logind Config (Your Tweak)
# Ensures power button turns off PC, Lid closes suspends.
mkdir -p /etc/systemd/logind.conf.d
cat <<EOF | tee /etc/systemd/logind.conf.d/99-spidy-actions.conf
[Login]
HandlePowerKey=poweroff
HandleSuspendKey=suspend
HandleHibernateKey=hibernate
HandleLidSwitch=suspend
HandleLidSwitchDocked=ignore
IdleAction=ignore
IdleActionSec=30min
EOF

echo " -> Logind settings updated."

# ==============================================================================
# 4. USER PERMISSIONS
# ==============================================================================
echo "[-] Configuring Brightness Permissions for user: $REAL_USER"
usermod -aG video "$REAL_USER"

# ==============================================================================
# 5. HARDWARE TUNING
# ==============================================================================
echo "[-] Configuring Hardware Services..."

# Thermald: CRITICAL to prevent overheating/throttling.
if pacman -Qi thermald &> /dev/null; then
    systemctl enable --now thermald
    echo " -> Thermald enabled."
else
    echo " -> Installing Thermald..."
    pacman -S --noconfirm thermald
    systemctl enable --now thermald
fi


echo "=== ✅ Hardware Optimization Complete ==="
echo "Please reboot for Environment Variables (MALLOC/Drivers) to take effect."