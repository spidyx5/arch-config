#!/bin/bash

echo "=== Setting up System Services ==="

# ==============================================================================
# 1. NETWORKING (NetworkManager & DNS)
# ==============================================================================
echo "Configuring NetworkManager..."

# Create a config for custom DNS (Cloudflare/Quad9)
# Matches networking.nameservers
sudo mkdir -p /etc/NetworkManager/conf.d
cat <<EOF | sudo tee /etc/NetworkManager/conf.d/dns.conf
[main]
dns=default

[global-dns-domain-*]
servers=9.9.9.11,149.112.112.11,1.1.1.1
EOF

# Make NetworkManager Wait Online faster (matches systemd override)
sudo mkdir -p /etc/systemd/system/NetworkManager-wait-online.service.d
cat <<EOF | sudo tee /etc/systemd/system/NetworkManager-wait-online.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/nm-online -q
EOF

# ==============================================================================
# 2. FIREWALL (nftables)
# Matches networking.firewall
# ==============================================================================
echo "Configuring nftables..."
cat <<EOF | sudo tee /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;

        # Accept loopback
        iifname "lo" accept

        # Accept established/related
        ct state established,related accept

        # Trusted Interfaces (virbr0, docker0, podman0)
        iifname { "virbr0", "docker0", "podman0" } accept

        # ICMP (Ping)
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept

        # SSH, HTTP, HTTPS, WebProxy, Custom Ports
        tcp dport { 22, 80, 443, 8080, 59010, 59011 } accept
        udp dport { 59010, 59011 } accept
    }
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF

# ==============================================================================
# 3. POLKIT RULES
# Matches security.polkit.extraConfig
# ==============================================================================
echo "Configuring Polkit Rules..."
# Note: Arch Polkit rules are JavaScript files in /etc/polkit-1/rules.d/

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
# 4. PAM LIMITS (Gaming/Wine)
# Matches security.pam.loginLimits
# ==============================================================================
echo "Configuring PAM Limits..."
cat <<EOF | sudo tee /etc/security/limits.d/99-gaming.conf
* soft nofile 524288
* hard nofile 1048576
EOF

# ==============================================================================
# 5. SSH CONFIGURATION
# Matches services.openssh
# ==============================================================================
echo "Configuring SSH..."
# We use sed to edit the existing config file safely
SSHD_CONFIG="/etc/ssh/sshd_config"

if [ -f "$SSHD_CONFIG" ]; then
    sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
    sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
    sudo sed -i 's/^#X11Forwarding.*/X11Forwarding no/' "$SSHD_CONFIG"
    # Ensure Pubkey is on (usually default yes)
fi

# ==============================================================================
# 6. FLATPAK SETUP
# ==============================================================================
echo "Configuring Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# ==============================================================================
# 7. EARLYOOM CONFIGURATION
# Matches services.earlyoom
# ==============================================================================
echo "Configuring EarlyOOM..."
# Arch uses /etc/default/earlyoom
cat <<EOF | sudo tee /etc/default/earlyoom
EARLYOOM_ARGS="-m 5 -s 5 --prefer '(^|/)(java|chromium|firefox|zen|chrome|electron|code)$' --avoid '(^|/)(steam|gamescope|Xwayland|kwin_wayland|Hyprland|niri)$'"
EOF

# ==============================================================================
# 8. GEOCLUE CONFIGURATION
# Matches services.geoclue2
# ==============================================================================
echo "Configuring Geoclue..."
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
# 9. ENABLE SERVICES
# ==============================================================================
echo "Enabling System Services..."

# Networking
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now nftables

# Security/Bus
sudo systemctl enable --now apparmor
sudo systemctl enable --now dbus-broker.service
sudo systemctl --global enable dbus-broker.service

# Hardware/Power
sudo systemctl enable --now upower
sudo systemctl enable --now fwupd
sudo systemctl enable --now earlyoom
sudo systemctl enable --now fstrim.timer
sudo systemctl enable --now lvm2-monitor

# SSH
sudo systemctl enable --now sshd

# Geolocation
sudo systemctl enable --now geoclue

echo "System Services setup complete."
