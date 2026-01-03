#!/bin/bash

# Ensure sudo
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (sudo)"
  exit
fi

# ==============================================================================
# 1. CONFIGURATION
# ==============================================================================

# User Home Detection
USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
CONFIG_DIR="$USER_HOME/.config/arch-config"

# Wallpaper Config
WALLPAPER_SRC="$CONFIG_DIR/wallpapers/26.png"
WALLPAPER_DEST="/boot/wallpaper.png"

# Limine Config
LIMINE_CONF="/boot/limine.conf"


NEW_PARAMS="nvme_core.default_ps_max_latency_us=0 \
mitigations=off \
rootflags=noatime \
nowatchdog \
kernel.split_lock_mitigate=0 \
init_on_alloc=0 init_on_free=0 \
resume=/dev/mapper/mock-spring \
zswap.enabled=1 \
randomize_kstack_offset=on \
vsyscall=none slab_nomerge page_alloc.shuffle=1 \
lsm=landlock,lockdown,yama,integrity,apparmor,bpf \
quiet splash plymouth.use-simpledrm \
acpi_sleep_default=deep acpi_sleep=nonvs mem_sleep_default=deep \
intel_iommu=on iommu=pt \
kvm-intel.nested=0 \
rd.systemd.show_status=false udev.log_level=3 \
i915.enable_guc=3 \
transparent_hugepage=always"

echo "=========================================="
echo "   🕷️ Spidy Limine Auto-Configurator"
echo "=========================================="

# ==============================================================================
# 2. WALLPAPER INSTALLATION
# ==============================================================================
echo "[*] Checking for wallpaper..."

if [ -f "$WALLPAPER_SRC" ]; then
    cp "$WALLPAPER_SRC" "$WALLPAPER_DEST"
    # Ensure readable by bootloader
    chmod 644 "$WALLPAPER_DEST"
    echo "    -> Installed to $WALLPAPER_DEST"
else
    echo "[!] WARNING: Wallpaper not found at source!"
fi

# ==============================================================================
# 3. DETECT ROOT FILESYSTEM UUID
# ==============================================================================
echo "[*] Detecting Root UUID..."
ROOT_UUID=$(findmnt / -n -o UUID)

if [ -z "$ROOT_UUID" ]; then
    echo "[!] ERROR: Could not detect Root UUID. Exiting."
    exit 1
fi

CURRENT_ROOT="root=UUID=$ROOT_UUID"
echo "    -> Root: $CURRENT_ROOT"

# ==============================================================================
# 4. DETECT MICROCODE 
# ==============================================================================
UCODE_PATH=""
if [ -f "/boot/intel-ucode.img" ]; then
    echo "    -> Detected Intel Microcode"
    UCODE_PATH="module_path: boot():/intel-ucode.img"
else
    echo "    [!] WARNING: No Intel Microcode found in /boot"
fi

# ==============================================================================
# 5. GENERATE LIMINE CONFIG
# ==============================================================================
TEMP_CONF=$(mktemp)

# Write Header
cat <<EOF > "$TEMP_CONF"
timeout: 5
wallpaper: boot():/wallpaper.png
wallpaper_style: stretched
interface_branding: Spidy OS

EOF

echo "[*] Scanning for kernels in /boot..."
FOUND_KERNEL=0

for kernel_path in /boot/vmlinuz-*; do
    [ -e "$kernel_path" ] || continue
    FOUND_KERNEL=1

    k_filename=$(basename "$kernel_path")
    # Clean name: vmlinuz-linux-cachyos -> linux-cachyos
    variant="${k_filename#vmlinuz-}"
    
    initramfs_img="initramfs-${variant}.img"
    initramfs_fallback="initramfs-${variant}-fallback.img"

    echo "    -> Adding Entry: $variant"
    
    # 5a. MAIN Entry
    cat <<EOF >> "$TEMP_CONF"
/$variant
    protocol: linux
    kernel_path: boot():/$k_filename
    $UCODE_PATH
    module_path: boot():/$initramfs_img
    cmdline: $CURRENT_ROOT rw rootflags=subvol=/@ $NEW_PARAMS

EOF

    # 5b. FALLBACK Entry
    if [ -f "/boot/$initramfs_fallback" ]; then
        cat <<EOF >> "$TEMP_CONF"
/$variant (Fallback)
    protocol: linux
    kernel_path: boot():/$k_filename
    $UCODE_PATH
    module_path: boot():/$initramfs_fallback
    cmdline: $CURRENT_ROOT rw rootflags=subvol=/@
EOF
    fi
done

if [ "$FOUND_KERNEL" -eq 0 ]; then
    echo "[!] ERROR: No kernels found in /boot! Aborting."
    rm "$TEMP_CONF"
    exit 1
fi

# ==============================================================================
# 6. APPLY CONFIG
# ==============================================================================
echo "[*] Writing final config to $LIMINE_CONF..."

# Backup existing if it's not a symlink
if [ -f "$LIMINE_CONF" ] && [ ! -L "$LIMINE_CONF" ]; then
    cp "$LIMINE_CONF" "$LIMINE_CONF.bak"
fi

mv "$TEMP_CONF" "$LIMINE_CONF"
chmod 644 "$LIMINE_CONF"

echo "=== ✅ Limine Updated Successfully ==="