#!/bin/bash

echo "=== Configuring Virtualization & Containers ==="

# ==============================================================================
# 1. LIBVIRT CONFIGURATION (Root execution & Permissions)
# ==============================================================================
echo "Configuring Libvirt..."

# Enable the service
sudo systemctl enable --now libvirtd

# Configure QEMU to run as ROOT (Matches your NixOS runAsRoot = true)
# NOTE: Running as root is less secure but required for some GPU passthrough/anti-detection hacks.
QEMU_CONF="/etc/libvirt/qemu.conf"

if [ -f "$QEMU_CONF" ]; then
    # Set user/group to root
    sudo sed -i 's/^#user = "root"/user = "root"/' "$QEMU_CONF"
    sudo sed -i 's/^#group = "root"/group = "root"/' "$QEMU_CONF"

    # Disable dynamic ownership (Matches dynamic_ownership = 0)
    sudo sed -i 's/^#dynamic_ownership = 1/dynamic_ownership = 0/' "$QEMU_CONF"

    # Allow simple namespaces (often fixes issues with /dev nodes)
    sudo sed -i 's/^#namespaces = .*/namespaces = []/' "$QEMU_CONF"
fi

# Add current user to libvirt group
sudo usermod -aG libvirt "$USER"
sudo usermod -aG kvm "$USER"

# Restart to apply changes
sudo systemctl restart libvirtd

# ==============================================================================
# 2. PODMAN CONFIGURATION
# ==============================================================================
echo "Configuring Podman..."

# Enable the socket (required for 'docker' compatibility and some tools)
systemctl --user enable --now podman.socket
sudo touch /etc/containers/nodocker # Prevents Docker CLI warning

# Enable Auto-Prune Timer (Matches your NixOS autoPrune)
# We create a systemd user timer for this.
mkdir -p ~/.config/systemd/user
cat <<EOF > ~/.config/systemd/user/podman-prune.service
[Unit]
Description=Podman Auto Prune

[Service]
Type=oneshot
ExecStart=/usr/bin/podman system prune --all -f
EOF

cat <<EOF > ~/.config/systemd/user/podman-prune.timer
[Unit]
Description=Run Podman Prune Weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now podman-prune.timer

# ==============================================================================
# 3. WAYDROID CONFIGURATION
# ==============================================================================
echo "Configuring Waydroid..."
# Waydroid requires the binder/ashmem modules (present in linux-cachyos)
# We enable the service, but 'waydroid init' must be run manually by the user
# because it downloads large images.
sudo systemctl enable --now waydroid-container

echo "Virtualization setup complete."
echo "IMPORTANT: For Waydroid, run 'sudo waydroid init' manually."
