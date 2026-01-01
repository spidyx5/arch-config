#!/bin/bash

echo "=== ⚙️ Setting up System Services (Spidy Profile) ==="

# ==============================================================================
# 1. NETWORK MANAGER (Boot Speed Tweak Only)
# Note: DNS and Firewall logic removed (Handled by optimize_net.sh)
# ==============================================================================
echo "[-] Configuring NetworkManager Boot Behavior..."

# Make NetworkManager Wait Online faster (Prevents boot hang waiting for connection)
sudo mkdir -p /etc/systemd/system/NetworkManager-wait-online.service.d
cat <<EOF | sudo tee /etc/systemd/system/NetworkManager-wait-online.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/nm-online -q
EOF

# ==============================================================================
# 2. POLKIT RULES (Permissions)
# ==============================================================================
echo "[-] Configuring Polkit Rules..."

cat <<EOF | sudo tee /etc/polkit-1/rules.d/49-wheel-permissions.rules
/* Allow wheel group to manage systemd units without password */
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});

/* Allow wheel group to mount drives without password */
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.filesystem-mount-system" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF

# ==============================================================================
# 3. PAM LIMITS (Gaming/Wine Performance)
# ==============================================================================
echo "[-] Configuring PAM Limits..."
cat <<EOF | sudo tee /etc/security/limits.d/99-gaming.conf
* soft nofile 524288
* hard nofile 1048576
EOF

# ==============================================================================
# 4. SSH CONFIGURATION
# ==============================================================================
echo "[-] Configuring SSH..."
SSHD_CONFIG="/etc/ssh/sshd_config"

if [ -f "$SSHD_CONFIG" ]; then
    # Disable Root Login for security
    sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
    # Enable Password Auth (Change to 'no' if you use keys only)
    sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
    # Disable X11 Forwarding (Performance/Security)
    sudo sed -i 's/^#X11Forwarding.*/X11Forwarding no/' "$SSHD_CONFIG"
else
    echo "Warning: sshd_config not found. Is openssh installed?"
fi

# ==============================================================================
# 5. FLATPAK SETUP
# ==============================================================================
echo "[-] Configuring Flatpak..."
if command -v flatpak &> /dev/null; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    echo "Flatpak not installed. Skipping..."
fi

# ==============================================================================
# 6. EARLYOOM CONFIGURATION (Prevent Freezes)
# ==============================================================================
echo "[-] Configuring EarlyOOM..."
# Installs earlyoom if missing
sudo pacman -S --needed --noconfirm earlyoom

cat <<EOF | sudo tee /etc/default/earlyoom
# Prefer killing browsers/electron apps. Avoid killing Steam/Wayland/Games.
EARLYOOM_ARGS="-m 5 -s 5 --prefer '(^|/)(java|chromium|firefox|zen|chrome|electron|code)$' --avoid '(^|/)(steam|gamescope|Xwayland|kwin_wayland|Hyprland|niri)$'"
EOF

# ==============================================================================
# 7. GEOCLUE CONFIGURATION (Night Light/Maps)
# ==============================================================================
echo "[-] Configuring Geoclue..."
# Ensure directory exists
sudo mkdir -p /etc/geoclue

cat <<EOF | sudo tee /etc/geoclue/geoclue.conf
[Agent]
Whitelist=gammastep
[gammastep]
Allowed=true
System=false
Users=

[network-nmea]
Enable=true
[network-geo]
Url=https://beacondb.net/v1/geolocate
SubmissionUrl=https://beacondb.net/v2/geosubmit
SubmissionNick=geoclue
EOF

# ==============================================================================
# 8. ENABLE SERVICES
# ==============================================================================
echo "[-] Enabling System Services..."

# Networking (Wait-online fix needs reload)
sudo systemctl daemon-reload

# Security & Message Bus
sudo systemctl enable --now dbus-broker.service
sudo systemctl --global enable dbus-broker.service
sudo systemctl enable --now apparmor

# Hardware & Power
sudo systemctl enable --now upower
sudo systemctl enable --now fwupd
sudo systemctl enable --now earlyoom
sudo systemctl enable --now fstrim.timer
sudo systemctl enable --now lvm2-monitor

# Remote Access
sudo systemctl enable --now sshd

# Location Services
sudo systemctl enable --now geoclue

echo "=== ✅ Services Optimization Complete ==="