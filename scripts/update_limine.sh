#!/bin/bash

# ==============================================================================
# 1. CONFIGURATION
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Source Wallpaper
WALLPAPER_SRC="$REPO_ROOT/wallpapers/6.png"
# Destination in ESP/Boot
WALLPAPER_DEST="/boot/wallpaper.png"
# Limine Config Location
LIMINE_CONF="/boot/limine.conf"
# Kernel Parameters to use
NEW_PARAMS="nvme_core.default_ps_max_latency_us=0 \
zswap.enabled=1 mitigations=off rootflags=noatime \
nowatchdog threadirqs kernel.split_lock_mitigate=0 \
init_on_alloc=1 init_on_free=1 randomize_kstack_offset=on \
vsyscall=none slab_nomerge page_alloc.shuffle=1 lsm=landlock,\
lockdown,yama,integrity,apparmor,bpf quiet splash plymouth.use-simpledrm \
acpi_sleep_default=deep acpi_sleep=nonvs mem_sleep_default=deep \
resume=/dev/mapper/mock-fang intel_idle.max_cstate=4 \
intel_pstate=passive intel_iommu=on i915.enable_gvt=1 \
kvm-intel.nested=0 iommu=pt rd.systemd.show_status=false \
udev.log_level=3"

echo "=========================================="
echo "   Limine Auto-Configurator"
echo "=========================================="

# ==============================================================================
# 2. WALLPAPER INSTALLATION
# ==============================================================================
if [ -f "$WALLPAPER_SRC" ]; then
    echo "[*] Installing wallpaper..."
    sudo cp "$WALLPAPER_SRC" "$WALLPAPER_DEST"
else
    echo "[!] WARNING: Wallpaper not found at $WALLPAPER_SRC"
    echo "    Skipping wallpaper copy (config will still try to load it)."
fi

# ==============================================================================
# 3. DETECT ROOT FILESYSTEM UUID
# ==============================================================================
# We try to detect the UUID of the root partition so we don't rely on existing config
echo "[*] Detecting Root UUID..."
ROOT_UUID=$(findmnt / -n -o UUID)

if [ -z "$ROOT_UUID" ]; then
    echo "[!] ERROR: Could not detect Root UUID. Exiting."
    exit 1
fi

CURRENT_ROOT="root=UUID=$ROOT_UUID"
echo "    -> Found Root: $CURRENT_ROOT"

# ==============================================================================
# 4. GENERATE LIMINE CONFIG
# ==============================================================================

# Create a temporary file to build the config
TEMP_CONF=$(mktemp)

# Write Header
cat <<EOF > "$TEMP_CONF"
timeout: 5
wallpaper: boot():/wallpaper.png
wallpaper_style: stretched

EOF

echo "[*] Scanning for kernels in /boot..."

# Loop through any file starting with vmlinuz- in /boot
FOUND_KERNEL=0

for kernel_path in /boot/vmlinuz-*; do
    # Check if file exists (handles case where no kernels found)
    [ -e "$kernel_path" ] || continue
    FOUND_KERNEL=1

    # Extract filename (e.g., vmlinuz-linux)
    k_filename=$(basename "$kernel_path")

    # Extract variant name (e.g., linux, linux-zen, linux-cachyos)
    # We strip 'vmlinuz-' from the start
    variant="${k_filename#vmlinuz-}"

    # Determine Initramfs names based on kernel name
    # Arch standard: vmlinuz-linux -> initramfs-linux.img
    initramfs_img="initramfs-${variant}.img"
    initramfs_fallback="initramfs-${variant}-fallback.img"

    # 4a. Add MAIN Entry
    echo "    -> Found Kernel: $variant"
    cat <<EOF >> "$TEMP_CONF"
/Arch Linux ($variant)
    protocol: linux
    kernel_path: boot:///$k_filename
    module_path: boot:///$initramfs_img
    cmdline: $CURRENT_ROOT rw $NEW_PARAMS

EOF

    # 4b. Add FALLBACK Entry (Only if fallback img exists)
    if [ -f "/boot/$initramfs_fallback" ]; then
        echo "       -> Added Fallback for $variant"
        cat <<EOF >> "$TEMP_CONF"
/Arch Linux ($variant) Fallback
    protocol: linux
    kernel_path: boot:///$k_filename
    module_path: boot:///$initramfs_fallback
    cmdline: $CURRENT_ROOT rw
EOF
    fi
done

if [ "$FOUND_KERNEL" -eq 0 ]; then
    echo "[!] ERROR: No kernels found in /boot! Aborting to prevent unbootable system."
    rm "$TEMP_CONF"
    exit 1
fi

# ==============================================================================
# 5. APPLY CONFIG
# ==============================================================================
echo "[*] Writing config to $LIMINE_CONF..."

# Backup existing
if [ -f "$LIMINE_CONF" ]; then
    sudo cp "$LIMINE_CONF" "$LIMINE_CONF.bak-$(date +%s)"
fi

# Move temp file to actual location
sudo mv "$TEMP_CONF" "$LIMINE_CONF"
sudo chmod 644 "$LIMINE_CONF"

echo "=========================================="
echo "   Limine Configuration Updated!"
echo "=========================================="
