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

# Function to safely append if not exists or update if exists
add_env_var() {
    local var_name=$1
    local var_line=$2
    if grep -q "^$var_name=" /etc/environment; then
        sed -i "s|^$var_name=.*|$var_line|" /etc/environment
        echo "    * Updated: $var_name"
    else
        echo "$var_line" | tee -a /etc/environment > /dev/null
        echo "    + Added: $var_name"
    fi
}

# 1. Intel Media Driver (Your Tweak)
add_env_var "LIBVA_DRIVER_NAME" "LIBVA_DRIVER_NAME=iHD"

# 2. MALLOC_ARENA_MAX (Improvement for Low RAM)
# This forces glibc to be aggressive about returning memory to the OS.
add_env_var "MALLOC_ARENA_MAX" "MALLOC_ARENA_MAX=2"

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