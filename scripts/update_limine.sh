#!/bin/bash

# Ensure sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
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
LIMINE_DEFAULT="/etc/default/limine"


NEW_PARAMS="nvme_core.default_ps_max_latency_us=0 \
mitigations=off rootflags=noatime \
nowatchdog threadirqs kernel.split_lock_mitigate=0 \
init_on_alloc=0 init_on_free=0 \
resume=/dev/mapper/mock-spring \
zswap.enabled=1 \
randomize_kstack_offset=on \
vsyscall=none slab_nomerge page_alloc.shuffle=1 \
lsm=landlock,lockdown,yama,integrity,apparmor,bpf \
quiet splash plymouth.use-simpledrm \
acpi_sleep_default=deep acpi_sleep=nonvs mem_sleep_default=deep \
intel_pstate=passive intel_iommu=on \
kvm-intel.nested=0 iommu=pt rd.systemd.show_status=false \
udev.log_level=3"

echo "=========================================="
echo "   🕷️ Spidy Limine Auto-Configurator"
echo "=========================================="

# ==============================================================================
# 2. WALLPAPER INSTALLATION
# ==============================================================================
echo "[*] Checking for wallpaper: $WALLPAPER_SRC"

if [ -f "$WALLPAPER_SRC" ]; then
    echo "    -> Found. Installing to $WALLPAPER_DEST..."
    cp "$WALLPAPER_SRC" "$WALLPAPER_DEST"
else
    echo "[!] WARNING: Wallpaper not found at source!"
    echo "    Limine config will point to it, but it will be black screen."
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
# 4. DETECT MICROCODE (Intel/AMD)
# ==============================================================================
UCODE_PATH=""
if [ -f "/boot/intel-ucode.img" ]; then
    echo "    -> Detected Intel Microcode"
    UCODE_PATH="module_path: boot():/intel-ucode.img"
elif [ -f "/boot/amd-ucode.img" ]; then
    echo "    -> Detected AMD Microcode"
    UCODE_PATH="module_path: boot():/amd-ucode.img"
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
    echo "[!] ERROR: No kernels found in /boot! Aborting safety check."
    rm "$TEMP_CONF"
    exit 1
fi

# ==============================================================================
# 6. APPLY CONFIG
# ==============================================================================
echo "[*] Writing final config to $LIMINE_CONF..."

# Backup existing
if [ -f "$LIMINE_CONF" ]; then
    cp "$LIMINE_CONF" "$LIMINE_CONF.bak"
fi

mv "$TEMP_CONF" "$LIMINE_CONF"
chmod 644 "$LIMINE_CONF"

echo "=== ✅ Limine Updated Successfully ==="
echo "Check /boot/limine.conf content to verify."