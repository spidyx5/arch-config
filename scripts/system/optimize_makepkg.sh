#!/bin/bash

set -euo pipefail

# Ensure sudo
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (sudo)"
  exit
fi

TARGET_CONF="/etc/makepkg.conf"
BACKUP_CONF="/etc/makepkg.conf.bak.$(date +%F_%H%M)"

echo "=== 🕷️ Generating Ultimate Makepkg Config ==="

# ==============================================================================
# 1. INSTALL TOOLCHAIN
# ==============================================================================
echo "[-] Verifying Toolchain..."
MISSING_DEPS=()
if ! command -v clang &>/dev/null; then MISSING_DEPS+=("clang"); fi
if ! command -v mold &>/dev/null; then MISSING_DEPS+=("mold"); fi
if ! command -v lld &>/dev/null; then MISSING_DEPS+=("lld"); fi
if ! command -v llvm-strip &>/dev/null; then MISSING_DEPS+=("llvm"); fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "    [!] Installing: ${MISSING_DEPS[*]}"
    pacman -S --noconfirm "${MISSING_DEPS[@]}"
fi

# ==============================================================================
# 2. BACKUP EXISTING CONFIG
# ==============================================================================
if [ -f "$TARGET_CONF" ]; then
    echo "[-] Backing up current config to $BACKUP_CONF"
    cp "$TARGET_CONF" "$BACKUP_CONF"
fi

# ==============================================================================
# 3. WRITE THE MERGED CONFIGURATION
# ==============================================================================
echo "[-] Writing new optimized configuration to $TARGET_CONF..."

# Using quoted 'EOF' to prevent variable expansion.
# This writes exactly what you see below into the file.
cat > "$TARGET_CONF" << 'EOF'
#!/hint/bash
# shellcheck disable=2034

#
# /etc/makepkg.conf
# SPIDY ULTIMATE OPTIMIZED (Clang + Mold)
#

#########################################################################
# SOURCE ACQUISITION
#########################################################################
DLAGENTS=('file::/usr/bin/curl -qgC - -o %o %u'
          'ftp::/usr/bin/curl -qgfC - --ftp-pasv --retry 3 --retry-delay 3 -o %o %u'
          'http::/usr/bin/curl -qgb "" -fLC - --retry 3 --retry-delay 3 -o %o %u'
          'https::/usr/bin/curl -qgb "" -fLC - --retry 3 --retry-delay 3 -o %o %u'
          'rsync::/usr/bin/rsync --no-motd -z %u %o'
          'scp::/usr/bin/scp -C %u %o')

VCSCLIENTS=('bzr::breezy'
            'fossil::fossil'
            'git::git'
            'hg::mercurial'
            'svn::subversion')

#########################################################################
# ARCHITECTURE, COMPILE FLAGS (SPIDY OPTIMIZED)
#########################################################################
CARCH="x86_64"
CHOST="x86_64-pc-linux-gnu"

# --- 1. Toolchain Definition (Clang + LLVM) ---
# Replacing GCC with Clang for faster builds and better optimization
export CC=clang
export CXX=clang++
export CPP="clang -E"

# Replacing GNU binutils with LLVM equivalents
export AR=llvm-ar
export NM=llvm-nm
export RANLIB=llvm-ranlib
export AS=llvm-as
export STRIP=llvm-strip
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export READELF=llvm-readelf

# --- 2. Compiler Flags (Intel 13th Gen) ---
# -march=native: Uses AVX2/VNNI instructions specific to your CPU
# -O3: Aggressive optimization
# -flto=thin: Clang's fast multi-threaded Link Time Optimization
# -fno-plt: Faster function calls
# -fno-semantic-interposition: Speed up shared libraries (Python/Libs)
CFLAGS="-march=native -O3 -pipe -fno-plt -fexceptions \
        -Wp,-D_FORTIFY_SOURCE=3 -Wformat -Werror=format-security \
        -fstack-clash-protection -fcf-protection \
        -fno-semantic-interposition -flto=thin"

# C++ Flags (Inherit CFLAGS + Assertions)
CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"

# --- 3. Linker Flags (Mold) ---
# -fuse-ld=mold: Force Clang to use Mold (fastest linker)
# -Wl,-O2: Linker optimization level
# -Wl,-z,pack-relative-relocs: Advanced relocation packing (CachyOS default)
LDFLAGS="-fuse-ld=mold -Wl,-O3 -Wl,--sort-common -Wl,--as-needed \
         -Wl,-z,relro -Wl,-z,now -Wl,--gc-sections \
         -Wl,-z,pack-relative-relocs"

# --- 4. Rust Flags ---
# Force Rust to use native CPU features and Mold linker
RUSTFLAGS="-C target-cpu=native -C link-arg=-fuse-ld=mold"

# --- 5. LTO Flags ---
# Must match CFLAGS (-flto=thin is for Clang)
LTOFLAGS="-flto=thin"

# --- 6. Make Flags ---
# Use all available CPU cores
MAKEFLAGS="-j$(nproc)"
NINJAFLAGS="-j$(nproc)"

# --- 7. Debug Flags ---
# (Rarely used since we disable debug, but good to have defined)
DEBUG_CFLAGS="-g"
DEBUG_CXXFLAGS="$DEBUG_CFLAGS"

#########################################################################
# BUILD ENVIRONMENT
#########################################################################
# !distcc: Build locally
# color: Colorized output
# !ccache: Don't cache (change to 'ccache' if you rebuild specific packages often)
# check: Run tests
# !sign: Don't sign packages
BUILDENV=(!distcc color !ccache check !sign)

#########################################################################
# GLOBAL PACKAGE OPTIONS
#########################################################################
# strip: Remove symbols (smaller binaries)
# docs: Keep documentation
# !libtool: Remove libtool files
# !staticlibs: Remove static libraries
# !debug: Do NOT build debug packages (saves space/time)
# lto: Enable LTO handling in build scripts
OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug lto !autodeps)

# Integrity Checks
INTEGRITY_CHECK=(sha256)

# Strip Options (Using llvm-strip settings)
STRIP_BINARIES="--strip-all"
STRIP_SHARED="--strip-unneeded"
STRIP_STATIC="--strip-debug"

# Directories
MAN_DIRS=(usr{,/local}{,/share}/{man,info})
DOC_DIRS=(usr/{,local/}{,share/}{doc,gtk-doc})
PURGE_TARGETS=(usr/{,share}/info/dir .packlist *.pod)
DBGSRCDIR="/usr/src/debug"
LIB_DIRS=('lib:usr/lib' 'lib32:usr/lib32')

#########################################################################
# COMPRESSION DEFAULTS
#########################################################################
# Optimized ZSTD: Level 19 (High compression), Multi-threaded
COMPRESSGZ=(gzip -c -f -n)
COMPRESSBZ2=(bzip2 -c -f)
COMPRESSXZ=(xz -c -z -)
COMPRESSZST=(zstd -c -z -q -19 -T0 -)
COMPRESSLRZ=(lrzip -q)
COMPRESSLZO=(lzop -q)
COMPRESSZ=(compress -c -f)
COMPRESSLZ4=(lz4 -q)
COMPRESSLZ=(lzip -c -f)

#########################################################################
# EXTENSION DEFAULTS
#########################################################################
PKGEXT='.pkg.tar.zst'
SRCEXT='.src.tar.gz'

# vim: set ft=sh ts=2 sw=2 et:
EOF

# ==============================================================================
# 4. CONFLICT RESOLUTION
# ==============================================================================
echo "[-] Disabling potential conflicting files in .d directory..."
CONF_D_DIR="/etc/makepkg.conf.d"

# We rename any existing .conf files to .conf.disabled
# This ensures that if CachyOS restores the "include" logic in the future,
# it won't load old conflicting settings.
if [ -d "$CONF_D_DIR" ]; then
    find "$CONF_D_DIR" -name "*.conf" -exec mv {} {}.disabled \; 2>/dev/null || true
    echo "    Disabled old files in $CONF_D_DIR"
fi

echo "=== ✅ Optimization Complete ==="
echo "Your /etc/makepkg.conf is now a single, merged, high-performance file."