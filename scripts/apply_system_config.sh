#!/bin/bash

echo "Applying Optimized System Configurations (Low RAM Usage Version)..."

# ==============================================================================
# 1. SYSCTL (Runtime Tuning) - /etc/sysctl.d/
# Matches boot.kernel.sysctl
# ==============================================================================
echo "Configuring Sysctl..."
cat <<EOF | sudo tee /etc/sysctl.d/99-spidy-tuning.conf
# --- Memory Management ---
# Set to 100 (default) to allow kernel to reclaim RAM from cache easily
#vm.vfs_cache_pressure=100
# Standard swappiness for Desktop use with 16GB RAM
vm.swappiness=60
# Keep this for games (Steam/Proton needs it), does not consume RAM directly
vm.max_map_count=2147483642
# Standard randomize bits
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

# --- Network Buffers (TUNED FOR <100Mbps / 16GB RAM) ---
# Default buffer sizes (approx 256KB)
net.core.rmem_default=262144
net.core.wmem_default=262144
# Max buffer sizes reduced from 16MB to 6MB (Plenty for 100Mbps)
net.core.rmem_max=6291456
net.core.wmem_max=6291456
net.core.netdev_budget=300
#net.core.netdev_max_backlog=5000
net.core.default_qdisc=cake
net.core.bpf_jit_harden=2

# --- TCP Optimizations ---
# TCP Read/Write Buffers: Min / Default / Max
# Max reduced to ~6MB (was 128MB). Prevents RAM bloat on heavy downloads.
net.ipv4.tcp_rmem=4096 87380 6291456
net.ipv4.tcp_wmem=4096 65536 6291456

net.ipv4.tcp_low_latency=1
net.ipv4.ip_forward=1
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_moderate_rcvbuf=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_syncookies=1

# --- Network Security ---
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.all.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
EOF

# ==============================================================================
# 2. MODULE LOADING - /etc/modules-load.d/
# Matches boot.kernelModules
# ==============================================================================
echo "Configuring Kernel Modules to Load..."
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
# kvmgt is for Intel GVT-g (sharing iGPU with VM).
# If you don't run VMs with graphics often, you can comment this out to save a small amount of RAM.
kvmgt
btrfs
dm-snapshot
dm-mod
dm-thin-pool
dm-mirror
EOF

# ==============================================================================
# 3. MODULE OPTIONS & BLACKLIST - /etc/modprobe.d/
# Matches boot.extraModprobeConfig & boot.blacklistedKernelModules
# ==============================================================================
echo "Configuring Module Options and Blacklists..."
cat <<EOF | sudo tee /etc/modprobe.d/spidy-options.conf
# --- Options ---
options v4l2loopback exclusive_caps=1 card_label="OBS Virtual Output"
options rtw88_core disable_lps_deep=y
options rtw88_pci disable_aspm=y
options bluetooth disable_ertm=1

# --- Blacklist ---
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
echo "Configuring Tmpfiles and Coredumps..."

# NOTE: Looking Glass requires shared memory. This line creates the permission,
# but RAM is only consumed when the Looking Glass application is actually RUNNING.
echo "f /dev/shm/looking-glass 0660 spidy kvm -" | sudo tee /etc/tmpfiles.d/looking-glass.conf

# Disable Coredump storage
sudo mkdir -p /etc/systemd/coredump.conf.d
cat <<EOF | sudo tee /etc/systemd/coredump.conf.d/disable.conf
[Coredump]
Storage=none
ProcessSizeMax=0
EOF

# ==============================================================================
# 5. INITRAMFS COMPRESSION
# ==============================================================================
echo "Configuring Initramfs Compression to ZSTD..."
if grep -q "^#COMPRESSION=\"zstd\"" /etc/mkinitcpio.conf; then
    sudo sed -i 's/^#COMPRESSION="zstd"/COMPRESSION="zstd"/' /etc/mkinitcpio.conf
elif grep -q "^COMPRESSION=" /etc/mkinitcpio.conf; then
    sudo sed -i 's/^COMPRESSION=.*/COMPRESSION="zstd"/' /etc/mkinitcpio.conf
else
    echo 'COMPRESSION="zstd"' | sudo tee -a /etc/mkinitcpio.conf
fi

# ==============================================================================
# 6. APPLY SETTINGS
# ==============================================================================
echo "Reloading systemd-tmpfiles and sysctl..."
sudo systemd-tmpfiles --create
sudo sysctl --system

echo "Optimization complete. RAM usage safeguards applied."
echo "NOTE: If you still see high RAM usage, check running applications (Browser/Electron apps)."
