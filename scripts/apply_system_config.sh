#!/bin/bash

echo "=== 🕷️ Applying Spidy System Configurations ==="

# ==============================================================================
# 1. SYSCTL (System Memory & Kernel Security)
# Location: /etc/sysctl.d/
# ==============================================================================
echo "[-] Configuring System Sysctl..."

cat <<EOF | sudo tee /etc/sysctl.d/99-spidy-sys-tuning.conf
# === Spidy System Tuning ===

# --- Memory Management (Low RAM Optimized) ---
# 100 = Fair reclaiming of directory cache (prevents stutter)
vm.vfs_cache_pressure=100
vm.swappiness=60

# Gaming Compatibility (Steam/Proton/ESYNC)
vm.max_map_count=2147483642

# Randomization (Security)
vm.mmap_rnd_bits=32
vm.mmap_rnd_compat_bits=16
vm.unprivileged_userfaultfd=0

# --- Kernel Security ---
kernel.sysrq=0
kernel.dmesg_restrict=1
kernel.nmi_watchdog=0
kernel.core_uses_pid=1
kernel.randomize_va_space=2
kernel.kptr_restrict=1
user.max_user_namespaces=10000

# --- Filesystem Security ---
fs.protected_fifos=2
fs.protected_regular=2
fs.suid_dumpable=0

# --- TTY Security ---
dev.tty.ldisc_autoload=0
EOF

# ==============================================================================
# 2. MODULE LOADING
# Location: /etc/modules-load.d/
# ==============================================================================
echo "[-] Configuring Kernel Modules..."
cat <<EOF | sudo tee /etc/modules-load.d/spidy-modules.conf
kvm
v4l2loopback
i2c-dev
efivarfs
uinput
tcp_bbr
hid_nintendo
xpad
tun
vhost_net
vfio_virqfd
kvm-intel
i915
btrfs
dm-snapshot
dm-mod
dm-thin-pool
dm-mirror
EOF

# ==============================================================================
# 3. MODULE OPTIONS & BLACKLIST
# Location: /etc/modprobe.d/
# ==============================================================================
echo "[-] Configuring Module Options and Blacklists..."
cat <<EOF | sudo tee /etc/modprobe.d/spidy-options.conf
# --- Options ---
options v4l2loopback exclusive_caps=1 card_label="OBS Virtual Output"
options rtw88_core disable_lps_deep=y
options rtw88_pci disable_aspm=y
options bluetooth disable_ertm=1

# --- Blacklist (Unused Protocols & File Systems) ---
blacklist af_802154
blacklist appletalk
blacklist atm
blacklist ax25
blacklist decnet
blacklist econet
blacklist ipx
blacklist n-hdlc
blacklist netrom
blacklist p8022
blacklist p8023
blacklist psnap
blacklist rds
blacklist rose
blacklist tipc
blacklist x25
blacklist adfs
blacklist affs
blacklist befs
blacklist bfs
blacklist cramfs
blacklist efs
blacklist erofs
blacklist exofs
blacklist freevxfs
blacklist gfs2
blacklist hfs
blacklist hfsplus
blacklist hpfs
blacklist jffs2
blacklist jfs
blacklist ksmbd
blacklist minix
blacklist nilfs2
blacklist omfs
blacklist qnx4
blacklist qnx6
blacklist sysv
blacklist udf
blacklist firewire-core
blacklist thunderbolt
blacklist vivid
blacklist pcspkr
blacklist snd_pcsp
blacklist iTCO_wdt
blacklist nouveau
blacklist radeon
EOF

# ==============================================================================
# 4. TMPFILES & COREDUMP
# ==============================================================================
echo "[-] Configuring Tmpfiles and Coredumps..."

# Permission for Looking Glass (Shared Memory)
echo "f /dev/shm/looking-glass 0660 spidy kvm -" | sudo tee /etc/tmpfiles.d/looking-glass.conf

# Disable Coredump (Saves disk space and I/O)
sudo mkdir -p /etc/systemd/coredump.conf.d
cat <<EOF | sudo tee /etc/systemd/coredump.conf.d/disable.conf
[Coredump]
Storage=none
ProcessSizeMax=0
EOF

# ==============================================================================
# 5. APPLY SETTINGS
# ==============================================================================
echo "[-] Reloading Configurations..."
sudo systemd-tmpfiles --create
sudo sysctl --system

echo "=== ✅ System Optimization Complete ==="
