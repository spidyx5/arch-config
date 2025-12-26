#!/bin/bash

echo "=== Fixing makepkg.conf Error ==="

# 1. Restore the default Arch Linux makepkg.conf
# We reinstall pacman to generate a fresh config file (makepkg.conf.pacnew)
echo "Downloading default configuration..."
sudo pacman -S --noconfirm pacman

# 2. Overwrite the corrupt file with the fresh default
if [ -f "/etc/makepkg.conf.pacnew" ]; then
    echo "Restoring default makepkg.conf..."
    sudo mv /etc/makepkg.conf.pacnew /etc/makepkg.conf
else
    echo "ERROR: Could not find default config. Please run 'sudo pacman -S pacman' manually."
    exit 1
fi

# 3. Re-apply the SAFE Optimizations
echo "Re-applying High Performance Settings..."
CONF="/etc/makepkg.conf"
CORES=$(nproc)

# Aggressive flags (One line to prevent errors)
FLAGS="-march=native -O3 -pipe -fno-plt -fexceptions -Wformat -Werror=format-security -fstack-clash-protection -fcf-protection -fstack-protector-strong -flto=auto -fomit-frame-pointer -ffunction-sections -fdata-sections -fno-semantic-interposition"

cat <<EOF | sudo tee -a $CONF > /dev/null

#############################################
# OPTIMIZED PERFORMANCE SETTINGS
#############################################
MAKEFLAGS="-j$CORES"
CFLAGS="$FLAGS"
CXXFLAGS="$FLAGS"
PKGEXT='.pkg.tar.zst'
COMPRESSZSTD=(zstd -c -T0 -)
EOF

# Linker settings (Only if mold is present)
if command -v mold &> /dev/null; then
    cat <<EOF | sudo tee -a $CONF > /dev/null
LDFLAGS="-Wl,-O2,--sort-common,--as-needed,-z,relro,-z,now -Wl,--gc-sections -fuse-ld=mold"
RUSTFLAGS="-C link-arg=-fuse-ld=mold"
EOF
fi

# Clang settings (Only if clang is installed)
if command -v clang &> /dev/null; then
    cat <<EOF | sudo tee -a $CONF > /dev/null
export CC=clang
export CXX=clang++
EOF
fi

echo "✅ Repair complete! Try running paru again."