#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
BROWSER="zen.desktop"
FILE_MGR="nemo.desktop"
EDITOR="org.kde.kate.desktop"
IMG_VIEWER="imv.desktop"
MEDIA_PLAYER="mpv.desktop"

# Terminal Selection (ghostty, kitty, alacritty)
MY_TERM="ghostty"
TERM_ARG="-e" # Use -e for ghostty/kitty/alacritty

# Directories
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
NEMO_ACTION_DIR="$HOME/.local/share/nemo/actions"
BIN_DIR="$HOME/.local/bin"

echo "=== 🛠️ Configuring XDG & Nemo (Safe Mode) ==="

# ==============================================================================
# 1. MIME TYPES (With Backup)
# ==============================================================================
echo "[-] Configuring Default Apps..."
MIME_FILE="$HOME/.config/mimeapps.list"

# ⚠️ SAFETY CHECK: Backup existing file
if [ -f "$MIME_FILE" ]; then
    echo "    ! Existing mimeapps.list found. Backing up to mimeapps.list.bak"
    cp "$MIME_FILE" "$MIME_FILE.bak"
fi

cat <<EOF > "$MIME_FILE"
[Default Applications]
# Web
text/html=$BROWSER
x-scheme-handler/http=$BROWSER
x-scheme-handler/https=$BROWSER
x-scheme-handler/about=$BROWSER
x-scheme-handler/unknown=$BROWSER

# File Management
inode/directory=$FILE_MGR
application/zip=$FILE_MGR
application/x-7z-compressed=$FILE_MGR
application/x-tar=$FILE_MGR
application/gzip=$FILE_MGR

# Text & Code
text/plain=$EDITOR
text/markdown=$EDITOR
application/json=$EDITOR
application/xml=$EDITOR
text/x-python=$EDITOR
text/x-shellscript=$EDITOR
text/x-c++=$EDITOR
text/x-rust=$EDITOR

# Images
image/jpeg=$IMG_VIEWER
image/png=$IMG_VIEWER
image/gif=$IMG_VIEWER
image/webp=$IMG_VIEWER
image/svg+xml=$IMG_VIEWER

# Media
video/mp4=$MEDIA_PLAYER
video/x-matroska=$MEDIA_PLAYER
video/webm=$MEDIA_PLAYER
audio/mpeg=$MEDIA_PLAYER
audio/flac=$MEDIA_PLAYER
audio/x-wav=$MEDIA_PLAYER

# PDF
application/pdf=$BROWSER
EOF

# ==============================================================================
# 2. FIX NEMO: TERMINAL (GSettings)
# ==============================================================================
echo "[-] Configuring Nemo Terminal..."

# Create the wrapper script (Safe to overwrite as it's a generated binary)
mkdir -p "$BIN_DIR"
cat <<EOF > "$BIN_DIR/xdg-terminal-exec"
#!/bin/sh
if command -v $MY_TERM >/dev/null 2>&1; then
    exec $MY_TERM "\$@"
elif command -v kitty >/dev/null 2>&1; then
    exec kitty "\$@"
else
    exec x-terminal-emulator "\$@"
fi
EOF
chmod +x "$BIN_DIR/xdg-terminal-exec"

# Apply to Nemo settings
if command -v gsettings >/dev/null 2>&1; then
    CURRENT_TERM=$(gsettings get org.cinnamon.desktop.default-applications.terminal exec)
    echo "    Current Nemo terminal: $CURRENT_TERM"
    
    # Only apply if different or forced
    gsettings set org.cinnamon.desktop.default-applications.terminal exec "$MY_TERM"
    gsettings set org.cinnamon.desktop.default-applications.terminal exec-arg "$TERM_ARG"
    echo "    -> Set Nemo to use '$MY_TERM'"
fi

# ==============================================================================
# 3. FIX NEMO: OPEN AS ROOT
# ==============================================================================
echo "[-] Creating 'Open as Root' Action..."
mkdir -p "$NEMO_ACTION_DIR"

# This file doesn't usually conflict with dotfiles, but we overwrite to ensure it works
cat <<EOF > "$NEMO_ACTION_DIR/open_as_root.nemo_action"
[Nemo Action]
Name=Open as Root
Comment=Open the current folder as root
Icon=dialog-password
Selection=Any
Extensions=dir;
# Fix for Wayland Root GUI
Exec=pkexec env DISPLAY=\$DISPLAY XAUTHORITY=\$XAUTHORITY nemo %F
EOF

# ==============================================================================
# 4. DIRECTORIES (Non-Destructive)
# ==============================================================================
echo "[-] Checking Directories..."
xdg-user-dirs-update
mkdir -p "$SCREENSHOT_DIR"

USER_DIRS="$HOME/.config/user-dirs.dirs"
if [ -f "$USER_DIRS" ]; then
    if ! grep -q "XDG_SCREENSHOTS_DIR" "$USER_DIRS"; then
        echo "XDG_SCREENSHOTS_DIR=\"$SCREENSHOT_DIR\"" >> "$USER_DIRS"
        echo "    -> Added Screenshots directory to config."
    fi
fi

echo "=== ✅ Setup Complete (Backups created) ==="
echo "If something broke, restore from ~/.config/mimeapps.list.bak"
echo "Restart Nemo with: nemo -q"