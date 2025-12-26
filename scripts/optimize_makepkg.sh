#!/bin/bash

echo "Configuring Makepkg for High Performance (Native + Mold)..."

CONF="/etc/makepkg.conf"

# 1. Configure CPU Threads
# Use all cores for compiling
CORES=$(nproc)
sudo sed -i "s/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$CORES\"/" $CONF
sudo sed -i "s/^MAKEFLAGS=.*/MAKEFLAGS=\"-j$CORES\"/" $CONF

# 2. Define Aggressive Flags (Based on your Nix Config)
# We use -march=native to target YOUR specific CPU.
AGGRESSIVE_CFLAGS="-march=native -O3 -pipe -fno-plt -fexceptions \
-Wp,-D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security \
-fstack-clash-protection -fcf-protection \
-flto=auto -fomit-frame-pointer \
-ffunction-sections -fdata-sections -fno-semantic-interposition"

# 3. Apply CFLAGS / CXXFLAGS
sudo sed -i "s|^CFLAGS=.*|CFLAGS=\"$AGGRESSIVE_CFLAGS\"|" $CONF
sudo sed -i "s|^CXXFLAGS=.*|CXXFLAGS=\"$AGGRESSIVE_CFLAGS\"|" $CONF

# 4. Configure Linker (Mold + GC Sections)
if command -v mold &> /dev/null; then
    echo "Mold linker detected. Enabling..."

    # -Wl,--gc-sections: Removes unused code (matches your Nix config)
    # -fuse-ld=mold: Use the high-performance linker
    NEW_LDFLAGS="-Wl,-O2,--sort-common,--as-needed,-z,relro,-z,now -Wl,--gc-sections -fuse-ld=mold"

    sudo sed -i "s|^LDFLAGS=.*|LDFLAGS=\"$NEW_LDFLAGS\"|" $CONF

    # Enable Rust to use Mold too
    if grep -q "^RUSTFLAGS=" $CONF; then
        sudo sed -i "s|^RUSTFLAGS=.*|RUSTFLAGS=\"-C link-arg=-fuse-ld=mold\"|" $CONF
    else
        echo 'RUSTFLAGS="-C link-arg=-fuse-ld=mold"' | sudo tee -a $CONF
    fi
else
    echo "WARNING: Mold not found. Using default linker."
fi

# 5. Compression Settings (ZSTD)
sudo sed -i "s/^PKGEXT=.*/PKGEXT='.pkg.tar.zst'/" $CONF
sudo sed -i "s/^COMPRESSZSTD=.*/COMPRESSZSTD=(zstd -c -T0 -)/" $CONF

echo "Makepkg optimized."
echo "export CC=clang" | sudo tee -a $CONF
echo "export CXX=clang++" | sudo tee -a $CONF
