#!/bin/bash

CONF="/etc/makepkg.conf"
CORES=$(nproc)

echo "Backing up makepkg.conf..."
sudo cp $CONF "$CONF.bak"

echo "Configuring Makepkg for High Performance..."

# 1. Define Aggressive Flags (ALL ON ONE LINE to prevent errors)
# We keep -Wp,-D_FORTIFY_SOURCE=3 because it is a valid security flag.
AGGRESSIVE_CFLAGS="-march=native -O3 -pipe -fno-plt -fexceptions -Wp,-D_FORTIFY_SOURCE=3 -Wformat -Werror=format-security -fstack-clash-protection -fcf-protection -flto=auto -fomit-frame-pointer -ffunction-sections -fdata-sections -fno-semantic-interposition"

# 2. Append Settings to the END of the file
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
    
    # Flags on one line to be safe
    NEW_LDFLAGS="-Wl,-O2,--sort-common,--as-needed,-z,relro,-z,now -Wl,--gc-sections -fuse-ld=mold"
    
    cat <<EOF | sudo tee -a $CONF > /dev/null

# Linker Flags
LDFLAGS="$NEW_LDFLAGS"
RUSTFLAGS="-C link-arg=-fuse-ld=mold"
EOF

else
    echo "WARNING: Mold not found. Skipping linker flags."
fi

# 4. Compression Settings
cat <<EOF | sudo tee -a $CONF > /dev/null

# Compression
PKGEXT='.pkg.tar.zst'
COMPRESSZSTD=(zstd -c -T0 -)
EOF

# 5. WARNING: Forcing Clang (Commented out for safety)
# Many AUR packages (like Nvidia drivers or older tools) WILL FAIL if you force Clang here.
# Only uncomment this if you know exactly what you are doing.

# cat <<EOF | sudo tee -a $CONF > /dev/null
# export CC=clang
# export CXX=clang++
# EOF

echo "Makepkg optimized successfully."