#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

# Detect Real User
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "=== 🕷️ Configuring Virtualization (Spidy Low-RAM Profile) ==="

# ==============================================================================
# 1. KERNEL SAMEPAGE MERGING (KSM) - CRITICAL FOR 16GB RAM
# ==============================================================================
echo "[-] Enabling KSM (Kernel Samepage Merging)..."
# KSM deduplicates memory. If Windows and Waydroid both load the same library,
# KSM merges them into one RAM block. Saves GBs of RAM.
if [ -f /sys/kernel/mm/ksm/run ]; then
    echo 1 | tee /sys/kernel/mm/ksm/run
    # Sleep 200ms between scans (Aggressive but low CPU usage)
    echo 200 | tee /sys/kernel/mm/ksm/sleep_millisecs
else
    echo "    ! KSM not supported by kernel (Skipping)"
fi

# ==============================================================================
# 2. LIBVIRT & QEMU (Windows VM / GPU Passthrough)
# ==============================================================================
echo "[-] Configuring Libvirt & QEMU..."

# Install packages:
# - qemu-desktop: The emulator
# - virt-manager: GUI
# - swtpm: TPM 2.0 emulator (REQUIRED for Windows 11)
# - ovmf: UEFI BIOS
pacman -S --needed --noconfirm qemu-desktop libvirt-venus edk2-ovmf swtpm virt-manager dnsmasq iptables-nft

# Enable Services
systemctl enable --now libvirtd
systemctl enable --now virtlogd

# Add user to groups (Crucial for access without 'sudo')
usermod -aG libvirt,kvm,input,disk,audio,video "$REAL_USER"

# Configure QEMU (Low Latency Audio & Permissions)
QEMU_CONF="/etc/libvirt/qemu.conf"

# Backup existing config
[ ! -f "$QEMU_CONF.bak" ] && cp "$QEMU_CONF" "$QEMU_CONF.bak"

cat <<EOF > "$QEMU_CONF"
# === Spidy QEMU Config ===

# 1. Audio: Use PulseAudio/Pipewire (Best for Gaming Latency)
audio_driver = "pa"

# 2. Security: Run as root is bad. Libvirt defaults to 'nobody:kvm' or dynamic.
# We stick to dynamic ownership but allow specific device access.

# 3. Device ACLs (Required for GPU/USB Passthrough)
# Allows the VM to access the VFIO groups 
cgroup_device_acl = [
    "/dev/null", "/dev/full", "/dev/zero",
    "/dev/random", "/dev/urandom",
    "/dev/ptmx", "/dev/kvm",
    "/dev/vfio/vfio", 
    "/dev/vfio/1", "/dev/vfio/2", "/dev/vfio/3", "/dev/vfio/4",
    "/dev/dri/card0", "/dev/dri/renderD129"
]

# 4. NVMe Passthrough Fix
namespaces = []
EOF

# Restart to apply
systemctl restart libvirtd

# ==============================================================================
# 3. PODMAN (High Perf / Low RAM)
# ==============================================================================
echo "[-] Configuring Podman with crun..."

# Install 'crun'. It is written in C.
# 'runc' (default) is written in Go and uses ~15MB more RAM per container.
pacman -S --needed --noconfirm podman crun netavark aardvark-dns

# Configure Podman to use crun by default
mkdir -p /etc/containers
cat <<EOF > /etc/containers/containers.conf
[engine]
runtime = "crun"
# Use netavark for better network performance (Rust-based)
network_cmd = "/usr/lib/podman/netavark"
EOF

# Prevent Docker CLI warning
touch /etc/containers/nodocker

# Setup User Systemd Services (Auto-Prune)
USER_SYSTEMD_DIR="$USER_HOME/.config/systemd/user"
mkdir -p "$USER_SYSTEMD_DIR"

# Service: Prune unused images/containers
cat <<EOF > "$USER_SYSTEMD_DIR/podman-prune.service"
[Unit]
Description=Podman Auto Prune
[Service]
Type=oneshot
ExecStart=/usr/bin/podman system prune --all -f
EOF

# Timer: Run weekly
cat <<EOF > "$USER_SYSTEMD_DIR/podman-prune.timer"
[Unit]
Description=Run Podman Prune Weekly
[Timer]
OnCalendar=weekly
Persistent=true
[Install]
WantedBy=timers.target
EOF

# Fix Ownership
chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config"

echo " -> Podman configured to use 'crun' (Saves RAM)."

# ==============================================================================
# 4. WAYDROID (Gaming)
# ==============================================================================
echo "[-] Configuring Waydroid..."

pacman -S --needed --noconfirm waydroid

# Enable Container Service
systemctl enable --now waydroid-container

# ==============================================================================
# 5. PASSTHROUGH PREP 
# ==============================================================================
echo "[-] Setting up VFIO modules..."

# Create modprobe config to load VFIO drivers early
cat <<EOF > /etc/modules-load.d/vfio.conf
#vfio
#vfio_pci
#vfio_iommu_type1
EOF

echo "=== ✅ Virtualization Optimization Complete ==="
echo "MANUAL STEPS REQUIRED FOR $REAL_USER:"
echo "--------------------------------------------------------"
echo "1. Enable Podman Timer:"
echo "   systemctl --user enable --now podman-prune.timer"
echo ""
echo "2. Initialize Waydroid (Downloads Android Image):"
echo "   sudo waydroid init"
echo ""
echo "3. Waydroid Gaming :"
echo "   Install libhoudini (ARM translation) or gaming won't work."
echo "   Run: git clone https://github.com/waydroid-extras/waydroid-extras.git"
echo "   Then: sudo python3 waydroid-extras/waydroid-extras.py -i libhoudini"
echo "--------------------------------------------------------"