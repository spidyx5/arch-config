#!/bin/bash

CONF="/etc/makepkg.conf"
CORES=$(nproc)

echo "Backing up makepkg.conf..."
sudo cp $CONF "$CONF.bak"

echo "Configuring Makepkg for High Performance (Clang + Mold)..."

# 1. Define Aggressive Flags
# FIXED: Put on ONE LINE to absolutely prevent the "-Wp command not found" error.
AGGRESSIVE_CFLAGS="-march=native -O3 -pipe -fno-plt -fexceptions -Wformat -Werror=format-security -fstack-clash-protection -fcf-protection -fstack-protector-strong -flto=auto -fomit-frame-pointer -ffunction-sections -fdata-sections -fno-semantic-interposition"

# 2. Append Settings
cat <<EOF | sudo tee -a $CONF > /dev/null

#############################################
# OPTIMIZED PERFORMANCE SETTINGS (User Added)
#############################################

# Compile Threads
MAKEFLAGS="-j$CORES"

# Compiler Flags
CFLAGS="$AGGRESSIVE_CFLAGS"
CXXFLAGS="$AGGRESSIVE_CFLAGS"
EOF

# 3. Handle Linker Logic
if command -v mold &> /dev/null; then
    echo "Mold linker detected. Appending mold config..."
    
    # Flags on one line for safety
    NEW_LDFLAGS="-Wl,-O2,--sort-common,--as-needed,-z,relro,-z,now -Wl,--gc-sections -fuse-ld=mold"
    
    cat <<EOF | sudo tee -a $CONF > /dev/null
LDFLAGS="$NEW_LDFLAGS"
RUSTFLAGS="-C link-arg=-fuse-ld=mold"
EOF

else
    echo "WARNING: Mold not found. Using standard linker optimizations."
    cat <<EOF | sudo tee -a $CONF > /dev/null
LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
EOF
fi

# 4. Compression & Extension Settings (UPDATED)
cat <<EOF | sudo tee -a $CONF > /dev/null

# Compression
# -T0 uses all cores. 
COMPRESSZSTD=(zstd -c -T0 -)

# Package & Source Extensions
# explicitly defining these fixes "valid package suffix" errors
PKGEXT='.pkg.tar.zst'
SRCEXT='.src.tar.gz'

EOF

# 5. Clang Configuration (With Safety Warning)
# We only enable this if Clang is actually installed.
if command -v clang &> /dev/null; then
    cat <<EOF | sudo tee -a $CONF > /dev/null

# Force Clang
# WARNING: If builds for Nvidia or DKMS fail, comment these two lines out!
export CC=clang
export CXX=clang++
EOF
    echo " -> Clang set as default compiler."
else
    echo " -> Clang not found. Keeping GCC as default."
fi

echo "Makepkg optimized successfully."