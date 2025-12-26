#!/bin/bash

# ==============================================================================
# 1. CONFIGURATION
# ==============================================================================

# Handle the ARCH_CONFIG_DIR environment variable or default to ~/.config/arch-config
CONFIG_DIR="${ARCH_CONFIG_DIR:-$HOME/.config/arch-config}"

# Source Wallpaper: Explicitly target '26.png' inside 'wallpapers' folder
WALLPAPER_SRC="$CONFIG_DIR/wallpapers/26.png"

# Destination in ESP/Boot (Limine reads from here)
WALLPAPER_DEST="/boot/wallpaper.png"

# Limine Config Locations
LIMINE_CONF="/boot/limine.conf"
LIMINE_DEFAULT="/etc/default/limine"

# === KERNEL PARAMS ===
# Removed machine-specific 'resume=' and 'i915' flags from previous steps. 
# Add them back if you specifically need them.
NEW_PARAMS="nvme_core.default_ps_max_latency_us=0 \
zswap.enabled=1 mitigations=off rootflags=noatime \
nowatchdog threadirqs kernel.split_lock_mitigate=0 \
init_on_alloc=1 init_on_free=1 randomize_kstack_offset=on \
vsyscall=none slab_nomerge page_alloc.shuffle=1 lsm=landlock,\
lockdown,yama,integrity,apparmor,bpf quiet splash plymouth.use-simpledrm \
acpi_sleep_default=deep  i915.enable_gvt=1 acpi_sleep=nonvs mem_sleep_default=deep \
intel_idle.max_cstate=4 \
intel_pstate=passive intel_iommu=on \
kvm-intel.nested=0 iommu=pt rd.systemd.show_status=false \
udev.log_level=3"

echo "=========================================="
echo "   Limine Auto-Configurator"
echo "=========================================="

# ==============================================================================
# 2. WALLPAPER INSTALLATION
# ==============================================================================
echo "[*] Checking for specific wallpaper: 26.png"
echo "    Source: $WALLPAPER_SRC"

if [ -f "$WALLPAPER_SRC" ]; then
    echo "    -> Found. Installing to $WALLPAPER_DEST..."
    sudo cp "$WALLPAPER_SRC" "$WALLPAPER_DEST"
else
    echo "[!] ERROR: Wallpaper not found!"
    echo "    Expected at: $WALLPAPER_SRC"
    echo "    Please verify the file exists."
    # We do not exit, we allow config update, but wallpaper won't work on boot
fi

# ==============================================================================
# 3. SET ESP_PATH
# ==============================================================================
if [ ! -f "$LIMINE_DEFAULT" ]; then
    echo "[*] Creating /etc/default/limine..."
    sudo touch "$LIMINE_DEFAULT"
fi

if grep -q "^ESP_PATH=" "$LIMINE_DEFAULT"; then
    echo "[*] ESP_PATH is already set."
else
    echo "[*] Detecting and setting ESP_PATH..."
    ESP_PATH="/boot"
    if [ -d "/efi" ]; then ESP_PATH="/efi"; elif [ -d "/boot/efi" ]; then ESP_PATH="/boot/efi"; fi
    echo "ESP_PATH=$ESP_PATH" | sudo tee -a "$LIMINE_DEFAULT" > /dev/null
fi

# ==============================================================================
# 4. DETECT ROOT FILESYSTEM UUID
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
# 5. GENERATE LIMINE CONFIG
# ==============================================================================
TEMP_CONF=$(mktemp)

# Write Header
# boot():/ refers to the root of the partition Limine booted from
cat <<EOF > "$TEMP_CONF"
timeout: 5
wallpaper: boot():/wallpaper.png
wallpaper_style: stretched

EOF

echo "[*] Scanning for kernels in /boot..."

FOUND_KERNEL=0

for kernel_path in /boot/vmlinuz-*; do
    [ -e "$kernel_path" ] || continue
    FOUND_KERNEL=1

    k_filename=$(basename "$kernel_path")
    variant="${k_filename#vmlinuz-}"
    
    initramfs_img="initramfs-${variant}.img"
    initramfs_fallback="initramfs-${variant}-fallback.img"

    echo "    -> Entry: Arch Linux ($variant)"
    
    # 5a. MAIN Entry
    cat <<EOF >> "$TEMP_CONF"
/Arch Linux ($variant)
    protocol: linux
    kernel_path: boot():/$k_filename
    module_path: boot():/$initramfs_img
    cmdline: $CURRENT_ROOT rw $NEW_PARAMS

EOF

    # 5b. FALLBACK Entry
    if [ -f "/boot/$initramfs_fallback" ]; then
        echo "       -> Added Fallback"
        cat <<EOF >> "$TEMP_CONF"
/Arch Linux ($variant) Fallback
    protocol: linux
    kernel_path: boot():/$k_filename
    module_path: boot():/$initramfs_fallback
    cmdline: $CURRENT_ROOT rw
EOF
    fi
done

if [ "$FOUND_KERNEL" -eq 0 ]; then
    echo "[!] WARNING: No kernels found! Config not updated."
    rm "$TEMP_CONF"
    exit 0
fi

# ==============================================================================
# 6. APPLY CONFIG
# ==============================================================================
echo "[*] Writing final config to $LIMINE_CONF..."

if [ -f "$LIMINE_CONF" ]; then
    sudo cp "$LIMINE_CONF" "$LIMINE_CONF.bak"
fi

sudo mv "$TEMP_CONF" "$LIMINE_CONF"
sudo chmod 644 "$LIMINE_CONF"

echo "DONE."