#!/bin/bash

# Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit
fi

# Detect the actual user who ran sudo (to avoid adding 'root' to groups)
REAL_USER=${SUDO_USER:-$USER}

echo "=== Configuring Hardware, Power & Time ==="

# ==============================================================================
# 1. ENVIRONMENT VARIABLES (Drivers)
# ==============================================================================
echo "Setting Environment Variables..."
if ! grep -q "LIBVA_DRIVER_NAME=iHD" /etc/environment; then
    echo "LIBVA_DRIVER_NAME=iHD" | tee -a /etc/environment
    echo " -> Added iHD driver. Ensure 'intel-media-driver' is installed via pacman."
fi

# ==============================================================================
# 2. TIME SETTINGS
# ==============================================================================
echo "Setting RTC to Local Time ..."
timedatectl set-local-rtc 1

# ==============================================================================
# 3. POWER MANAGEMENT (Sleep & Logind)
# ==============================================================================
echo "Configuring Sleep & Logind..."

# Sleep Config
cat <<EOF | tee /etc/systemd/sleep.conf
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
SuspendState=mem
AllowSuspendThenHibernate=no
AllowHybridSleep=yes
EOF

# Logind Config
# Using a drop-in file
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

echo " -> Logind settings updated. They will apply on next reboot."

# ==============================================================================
# 4. BRIGHTNESS
# ==============================================================================
echo "Configuring Brightness Permissions for user: $REAL_USER"
usermod -aG video "$REAL_USER"

# ==============================================================================
# 5. HARDWARE TUNING
# ==============================================================================
echo "Enabling Hardware Tuning Services..."

# Check if packages exist before enabling
if pacman -Qi thermald &> /dev/null; then
    systemctl enable --now thermald
    echo " -> Thermald enabled."
else
    echo " -> WARNING: 'thermald' package not found. Skipping."
fi

if pacman -Qi tuned &> /dev/null; then
    systemctl enable --now tuned
    tuned-adm profile throughput-performance
    echo " -> Tuned enabled and set to throughput-performance."
else
    echo " -> WARNING: 'tuned' package not found. Skipping."
fi

echo "=== Configuration Complete. Please Reboot. ==="