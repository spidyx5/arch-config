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
cat >"${CONF_DROPIN}" <<EOF
#########################################################################
# SPIDY HIGH-PERFORMANCE CONFIG (Clang + Mold)
# Overrides /etc/makepkg.conf
#########################################################################

# 1. Parallel Compilation
MAKEFLAGS="-j${CORES}"
NINJAFLAGS="-j${CORES}"

# 2. Toolchain Exports
# We force Clang and LLVM utilities explicitly.
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
# -O3: Maximum speed optimization
# -flto=thin: Multi-threaded LTO (Fast build, Low RAM, High Perf)
# -fno-plt: Direct function calls (Performance)
CFLAGS="-march=native -O3 -pipe -fno-plt -fexceptions \
        -Wp,-D_FORTIFY_SOURCE=3 -Wformat -Werror=format-security \
        -fstack-clash-protection -fcf-protection \
        -fno-semantic-interposition -flto=thin"

# Map CXX to C flags + C++ specific assertions
CXXFLAGS="\$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"

# 4. Linker Flags (Mold)
# -fuse-ld=mold: Force the Mold linker
# -Wl,-O2: Enable Linker optimizations (O2 is safer/better than O3 for linking)
# -Wl,--as-needed: Don't link libraries that aren't actually used
LDFLAGS="-fuse-ld=mold -Wl,-O2 -Wl,--sort-common -Wl,--as-needed \
         -Wl,-z,relro -Wl,-z,now -Wl,--gc-sections"

# 5. Rust Flags
# Optimize Rust builds for native CPU and use Mold linker
RUSTFLAGS="-C target-cpu=native -C link-arg=-fuse-ld=mold"

# 6. LTO Flags
# Must match CFLAGS (-flto=thin is best for Clang)
LTOFLAGS="-flto=thin"

# 7. Global Options
# !debug: Disable debug symbols (Saves disk space/time)
# lto: Enable LTO handling
OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug lto)

# 8. Compression (ZSTD Ultra)
# -19: Maximum compression (Good for archiving)
# -T0: Use all CPU threads
COMPRESSZST=(zstd -c -z -q -19 -T0 -)

# 9. Extensions
PKGEXT='.pkg.tar.zst'
SRCEXT='.src.tar.gz'
EOF

echo "[+] Success! Configuration written to:"
echo "    ${CONF_DROPIN}"
echo ""
#depends=('electron-latest')