#!/bin/bash
set -e

echo "=== Installing Custom Kernels (XanMod Edge & TKG Bore LLVM) ==="

# Function to check for commands
check_cmd() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: '$1' is not installed. Please install it first."
        exit 1
    fi
}

check_cmd paru
check_cmd jaq
check_cmd curl

# ==============================================================================
# 1. INSTALL XANMOD EDGE (AUR)
# ==============================================================================
echo "--- Step 1: Installing XanMod Edge (v3) from AUR ---"
# We use --needed to skip if already up to date
# We use --noconfirm to automate the process (be careful with this)
paru -S --needed --noconfirm linux-xanmod-edge-linux-bin-x64v3 linux-xanmod-edge-linux-headers-bin-x64v3

# ==============================================================================
# 2. INSTALL TKG BORE LLVM (GitHub Latest Release)
# ==============================================================================
echo "--- Step 2: Finding latest Linux TKG (Bore Scheduler + LLVM) ---"

REPO="Frogging-Family/linux-tkg"
API_URL="https://api.github.com/repos/$REPO/releases/latest"
TEMP_DIR=$(mktemp -d)

echo "Fetching release info from $REPO..."
# 1. Get the JSON
# 2. Filter assets where name contains 'tkg-bore-llvm' AND ends in 'x86_64.pkg.tar.zst'
# 3. Extract browser_download_url
DOWNLOAD_URLS=$(curl -sL -H "Accept: application/vnd.github+json" "$API_URL" | \
    jq -r '.assets[] | select(.name | test("linux[0-9]*-tkg-bore-llvm-.*x86_64.pkg.tar.zst$")) | .browser_download_url')

if [ -z "$DOWNLOAD_URLS" ]; then
    echo "Error: Could not find matching TKG packages in the latest release."
    echo "Check if the release naming convention has changed."
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "Found packages:"
echo "$DOWNLOAD_URLS"

cd "$TEMP_DIR"

# Download files
for url in $DOWNLOAD_URLS; do
    echo "Downloading $(basename "$url")..."
    curl -OL "$url"
done

# Install files
echo "Installing TKG Kernel..."
sudo pacman -U --noconfirm *.pkg.tar.zst

# Cleanup
cd ~
rm -rf "$TEMP_DIR"

# ==============================================================================
# 3. UPDATE INITRAMFS & BOOTLOADER
# ==============================================================================
echo "--- Step 3: Finalizing ---"

# Arch kernels usually trigger mkinitcpio hooks automatically, but we ensure it here.
# Note: TKG and Xanmod usually provide their own preset files.
sudo mkinitcpio -P

echo "Kernel installation complete."
echo "IMPORTANT: You must manually add these entries to /boot/limine.conf if Limine doesn't auto-detect them."
echo "Look in /boot for vmlinuz-linux-xanmod-edge-linux-bin-x64v3 and vmlinuz-linux*-tkg-bore-llvm*"
