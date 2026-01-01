#!/bin/bash
#
# optimize-makepkg-clang.sh
#
# High-Performance Makepkg Config for Spidy
# Toolchain: Clang + LLVM + Mold
# Conflict Resolution: Overwrites flags to prevent duplication.
#

set -euo pipefail

# Check for Root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit
fi

CONF_DIR="/etc/makepkg.conf.d"
CONF_DROPIN="${CONF_DIR}/99-spidy-clang-mold.conf"
CORES=$(nproc)

echo "=== 🕷️ Generating Clang/Mold Makepkg Config ==="
echo "    Detected CPU Cores: ${CORES}"

# 1. Check for Required Tools
echo "[-] Checking toolchain..."
MISSING_DEPS=()

if ! command -v clang &>/dev/null; then MISSING_DEPS+=("clang"); fi
if ! command -v mold &>/dev/null; then MISSING_DEPS+=("mold"); fi
if ! command -v lld &>/dev/null; then MISSING_DEPS+=("lld"); fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "    [!] Missing packages: ${MISSING_DEPS[*]}"
    echo "    Installing them now..."
    pacman -S --noconfirm "${MISSING_DEPS[@]}"
fi

# 2. Ensure Directory Exists
mkdir -p "${CONF_DIR}"

# 3. Write the Configuration
# We use 'cat' to completely define the file.
# Note: We do NOT use ${CFLAGS} inside the string to avoid duplication.
# We define the flags from scratch.

cat >"${CONF_DROPIN}" <<EOF
#########################################################################
# SPIDY HIGH-PERFORMANCE CONFIG (Clang + Mold)
# Overrides /etc/makepkg.conf
#########################################################################

# 1. Parallel Compilation
MAKEFLAGS="-j${CORES}"
NINJAFLAGS="-j${CORES}"

# 2. Toolchain Exports (Uncommented as requested)
# We force Clang and LLVM utilities.
export CC=clang
export CXX=clang++
export CPP="clang -E"
export LD=mold
export AR=llvm-ar
export NM=llvm-nm
export RANLIB=llvm-ranlib
export AS=llvm-as
export STRIP=llvm-strip
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export READELF=llvm-readelf

# 3. Compiler Flags (C/C++)
# -march=native: Optimize for YOUR cpu
# -O3: Maximum speed
# -flto=thin: Clang's preferred LTO (Faster build, great performance)
# -fno-plt: Direct calls (Speed)
CFLAGS="-march=native -O3 -pipe -fno-plt -fexceptions \
        -Wp,-D_FORTIFY_SOURCE=3 -Wformat -Werror=format-security \
        -fstack-clash-protection -fcf-protection \
        -fno-semantic-interposition -flto=thin"

# Map CXX to C flags + C++ specific assertions
CXXFLAGS="\$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"

# 4. Linker Flags
# -fuse-ld=mold: Use the Mold linker (Fastest)
# -Wl,-O2: Linker optimization level 2 (Best balance)
# -Wl,--as-needed: Drop unused deps
LDFLAGS="-fuse-ld=mold -Wl,-O3 -Wl,--sort-common -Wl,--as-needed \
         -Wl,-z,relro -Wl,-z,now -Wl,--gc-sections"

# 5. Rust Flags
# Target native cpu and force mold for Rust too
RUSTFLAGS="-C target-cpu=native -C link-arg=-fuse-ld=mold"

# 6. LTO Flags
# Since we define -flto=thin in CFLAGS, we match it here
LTOFLAGS="-flto=thin"

# 7. Global Options
# !debug: Save space/time
# lto: Enable LTO handling
OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug lto)

# 8. Compression (ZSTD Ultra)
# -19: High compression (slower packing, smaller size, fast unpacking)
# --threads=0: Use all cores
COMPRESSZST=(zstd -c -z -q -19 -T0 -)

# 9. Extensions
PKGEXT='.pkg.tar.zst'
SRCEXT='.src.tar.gz'
EOF

echo "[+] Success! Configuration written to:"
echo "    ${CONF_DROPIN}"
echo ""
echo "=== Summary ==="
echo "Compiler: Clang/LLVM (Exported)"
echo "Linker:   Mold (-fuse-ld=mold, -Wl,-O2)"
echo "Flags:    -march=native -O3 -flto=thin (No duplicates)"
echo "Rust:     Optimized for Native + Mold"