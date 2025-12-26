#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

# Detect the real user (since we are running as sudo)
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "=== Configuring Virtualization for User: $REAL_USER ==="

# ==============================================================================
# 1. LIBVIRT CONFIGURATION
# ==============================================================================
echo "Configuring Libvirt..."

# Enable the system-wide service
systemctl enable --now libvirtd

# Configure QEMU (Anti-detection / Root execution)
QEMU_CONF="/etc/libvirt/qemu.conf"

if [ -f "$QEMU_CONF" ]; then
    # Set user/group to root (matches NixOS runAsRoot)
    sed -i 's/^#user = "root"/user = "root"/' "$QEMU_CONF"
    sed -i 's/^#group = "root"/group = "root"/' "$QEMU_CONF"
    
    # Disable dynamic ownership
    sed -i 's/^#dynamic_ownership = 1/dynamic_ownership = 0/' "$QEMU_CONF"
    
    # Clear namespaces
    sed -i 's/^#namespaces = .*/namespaces = []/' "$QEMU_CONF"
fi

# FIXED: Add the REAL_USER to the groups, not root
usermod -aG libvirt "$REAL_USER"
usermod -aG kvm "$REAL_USER"

# Restart libvirt to apply config changes
systemctl restart libvirtd

# ==============================================================================
# 2. PODMAN CONFIGURATION
# ==============================================================================
echo "Configuring Podman..."

# Prevent Docker CLI warning
touch /etc/containers/nodocker

# FIXED: Create systemd user files in the REAL USER'S home directory
USER_SYSTEMD_DIR="$USER_HOME/.config/systemd/user"
mkdir -p "$USER_SYSTEMD_DIR"

# Create Prune Service
cat <<EOF > "$USER_SYSTEMD_DIR/podman-prune.service"
[Unit]
Description=Podman Auto Prune

[Service]
Type=oneshot
ExecStart=/usr/bin/podman system prune --all -f
EOF

# Create Prune Timer
cat <<EOF > "$USER_SYSTEMD_DIR/podman-prune.timer"
[Unit]
Description=Run Podman Prune Weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

# FIXED: Fix ownership so the user can actually use these files
chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config"

echo " -> Podman auto-prune timer created."

# ==============================================================================
# 3. WAYDROID CONFIGURATION
# ==============================================================================
echo "Configuring Waydroid..."
# Waydroid container service is system-wide
systemctl enable --now waydroid-container

# ==============================================================================
# 4. FINAL INSTRUCTIONS
# ==============================================================================
echo "=== Virtualization Setup Complete ==="
echo "NOTE: Some actions require user permissions and cannot be run by sudo."
echo "Please run the following commands manually as $REAL_USER (without sudo):"
echo ""
echo "  systemctl --user enable --now podman.socket"
echo "  systemctl --user enable --now podman-prune.timer"
echo "  sudo waydroid init"
echo ""