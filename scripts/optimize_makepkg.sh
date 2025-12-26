#!/bin/bash

CONF="/etc/makepkg.conf"
CORES=$(nproc)

echo "Backing up makepkg.conf..."
sudo cp $CONF "$CONF.bak"

echo "Configuring Makepkg for High Performance..."

# 1. Define Aggressive Flags
AGGRESSIVE_CFLAGS="-march=native -O3 -pipe -fno-plt -fexceptions \
-Wformat -Werror=format-security \
-fstack-clash-protection -fcf-protection \
-flto=auto -fomit-frame-pointer \
-ffunction-sections -fdata-sections -fno-semantic-interposition"

# 2. Append Settings to the END of the file (Overrides defaults safely)
cat <<EOF | sudo tee -a $CONF > /dev/null

#############################################
# OPTIMIZED PERFORMANCE SETTINGS (User Added)
#############################################

# Compile Threads
MAKEFLAGS="-j$CORES"

# Compiler Flags
CFLAGS="$AGGRESSIVE_CFLAGS"
CXXFLAGS="$AGGRESSIVE_CFLAGS"

# Linker Flags (Mold + GC)
EOF

# 3. Handle Linker Logic
if command -v mold &> /dev/null; then
    echo "Mold linker detected. Appending mold config..."
    
    NEW_LDFLAGS="-Wl,-O2,--sort-common,--as-needed,-z,relro,-z,now -Wl,--gc-sections -fuse-ld=mold"
    
    cat <<EOF | sudo tee -a $CONF > /dev/null
LDFLAGS="$NEW_LDFLAGS"
RUSTFLAGS="-C link-arg=-fuse-ld=mold"
EOF

else
    echo "WARNING: Mold not found. Skipping linker flags."
fi

# 4. Compression Settings & Compiler location
# It is better to append these as well to avoid regex issues
cat <<EOF | sudo tee -a $CONF > /dev/null

# Compression
PKGEXT='.pkg.tar.zst'
COMPRESSZSTD=(zstd -c -T0 -)

# Force Clang
export CC=clang
export CXX=clang++
EOF

echo "Makepkg optimized successfully."