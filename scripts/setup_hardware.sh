#!/bin/bash

echo "=== Configuring Hardware, Power & Time ==="

# ==============================================================================
# 1. ENVIRONMENT VARIABLES (Drivers)
# Matches environment.sessionVariables.LIBVA_DRIVER_NAME
# ==============================================================================
echo "Setting Environment Variables..."
# We use /etc/environment for global session variables
if ! grep -q "LIBVA_DRIVER_NAME=iHD" /etc/environment; then
    echo "LIBVA_DRIVER_NAME=iHD" | sudo tee -a /etc/environment
fi

# ==============================================================================
# 2. TIME SETTINGS
# Matches time.hardwareClockInLocalTime = true
# ==============================================================================
echo "Setting RTC to Local Time..."
# This fixes time sync issues when dual-booting Windows
timedatectl set-local-rtc 1

# ==============================================================================
# 3. POWER MANAGEMENT (Sleep & Logind)
# Matches systemd.sleep.extraConfig & services.logind.settings
# ==============================================================================
echo "Configuring Sleep & Logind..."

# Sleep Config (Hibernation support)
cat <<EOF | sudo tee /etc/systemd/sleep.conf
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
SuspendState=mem
AllowSuspendThenHibernate=no
AllowHybridSleep=yes
EOF

# Logind Config (Lid switch, Power key, Idle)
# We use a drop-in file to avoid overwriting defaults
sudo mkdir -p /etc/systemd/logind.conf.d
cat <<EOF | sudo tee /etc/systemd/logind.conf.d/99-spidy-actions.conf
[Login]
HandlePowerKey=poweroff
HandleSuspendKey=suspend
HandleHibernateKey=yes
HandleLidSwitch=suspend
HandleLidSwitchDocked=ignore
IdleAction=ignore
IdleActionSec=30min
EOF

# Restart logind to apply changes immediately
sudo systemctl restart systemd-logind

# ==============================================================================
# 4. BRIGHTNESS (Replaces Brillo)
# Matches hardware.brillo
# ==============================================================================
echo "Configuring Brightness Permissions..."
# 'brillo' on NixOS sets up udev rules. On Arch, 'brightnessctl' + 'video' group is standard.
# Ensure the current user is in the 'video' group to change brightness without sudo.
sudo usermod -aG video "$USER"

# ==============================================================================
# 5. HARDWARE TUNING (Tuned & Thermald)
# Matches services.tuned & services.thermald
# ==============================================================================
echo "Enabling Hardware Tuning Services..."

# Intel Thermal Daemon (Prevents overheating/throttling on Intel CPUs)
sudo systemctl enable --now thermald

# Tuned (Dynamic system tuning)
sudo systemctl enable --now tuned
# Set profile to 'balanced' or 'throughput-performance' as a baseline
sudo tuned-adm profile balanced

echo "Hardware configuration complete."
