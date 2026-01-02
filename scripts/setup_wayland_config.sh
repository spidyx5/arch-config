#!/bin/bash

# Ensure sudo
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root
  exit
fi

# Detect the Real User (Spidy) to fix file permissions later
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd $REAL_USER | cut -d: -f6)

echo "Target User: $REAL_USER"

# ==============================================================================
# 1. GLOBAL ENVIRONMENT VARIABLES
# ==============================================================================
echo "[-] Updating /etc/environment..."

# Function to safely append if not exists or update if exists
add_env_var() {
    local var_name=$1
    local var_line=$2
    if grep -q "^$var_name=" /etc/environment; then
        sed -i "s|^$var_name=.*|$var_line|" /etc/environment
        echo "    * Updated: $var_name"
    else
        echo "$var_line" | tee -a /etc/environment > /dev/null
        echo "    + Added: $var_name"
    fi
}

# iHD is the standard Intel Media Driver 
add_env_var "LIBVA_DRIVER_NAME" "LIBVA_DRIVER_NAME=iHD"
# Translation layer allows older apps 
add_env_var "VDPAU_DRIVER" "VDPAU_DRIVER=va_gl"
# Fixes crashes in Discord/OBS when screen sharing on some setups
add_env_var "VAAPI_DISABLE_ENCODER_CHECKING" "VAAPI_DISABLE_ENCODER_CHECKING=1"

# --- Wayland Core ---
add_env_var "EGL_PLATFORM" "EGL_PLATFORM=wayland"
# Vulkan renderer is generally faster and smoother for Arc GPUs on CachyOS
add_env_var "WLR_RENDERER" "WLR_RENDERER=vulkan"

# --- Toolkits (Qt / GTK / Java) ---
add_env_var "QT_QPA_PLATFORM" "QT_QPA_PLATFORM=wayland;xcb"
add_env_var "QT_QPA_PLATFORMTHEME" "QT_QPA_PLATFORMTHEME=qt6ct"
add_env_var "QT_WAYLAND_DISABLE_WINDOWDECORATION" "QT_WAYLAND_DISABLE_WINDOWDECORATION=1"
# NEW: Ensures Qt apps scale correctly if you change resolutions
add_env_var "QT_AUTO_SCREEN_SCALE_FACTOR" "QT_AUTO_SCREEN_SCALE_FACTOR=1"

add_env_var "SDL_VIDEODRIVER" "SDL_VIDEODRIVER=wayland"
add_env_var "CLUTTER_BACKEND" "CLUTTER_BACKEND=wayland"
add_env_var "GDK_BACKEND" "GDK_BACKEND=wayland,x11"
# NEW: Forces apps (Firefox, etc) to use the modern KDE/Hyprland file picker
add_env_var "GTK_USE_PORTAL" "GTK_USE_PORTAL=1"

add_env_var "ECORE_EVAS_ENGINE" "ECORE_EVAS_ENGINE=wayland-egl"
add_env_var "ELM_ENGINE" "ELM_ENGINE=wayland_egl"

# --- Java Fixes ---
add_env_var "_JAVA_AWT_WM_NONREPARENTING" "_JAVA_AWT_WM_NONREPARENTING=1"
# NEW: Fixes jagged/ugly fonts in Minecraft, IntelliJ, and other Java apps
add_env_var "_JAVA_OPTIONS" "_JAVA_OPTIONS=\"-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true\""

# --- Electron/Browsers Global Hints ---
add_env_var "MOZ_ENABLE_WAYLAND" "MOZ_ENABLE_WAYLAND=1"
# Note: Electron requires "HINT" in the env variable name
add_env_var "ELECTRON_OZONE_PLATFORM_HINT" "ELECTRON_OZONE_PLATFORM_HINT=wayland"


# ==============================================================================
# 2. CHROMIUM CONFIGURATION
# Location: ~/.config/chromium-flags.conf
# ==============================================================================
echo "[-] Configuring Chromium Flags..."
CONF_DIR="$USER_HOME/.config"
mkdir -p "$CONF_DIR"

cat <<EOF > "$CONF_DIR/chromium-flags.conf"

--ozone-platform=wayland
--enable-wayland-ime

# GPU Acceleration (Intel Arc Optimized)
# We enable 'VaapiVideoEncoder' because Arc supports hardware AV1 encoding
--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiVideoDecoder,CanvasOopRasterization,UseOzonePlatform,Vulkan
--enable-gpu-rasterization
--enable-zero-copy
--enable-native-gpu-memory-buffers
--enable-hardware-overlays

# Performance
--enable-smooth-scrolling
--ignore-gpu-blocklist
EOF

# Fix Permissions
chown "$REAL_USER:$REAL_USER" "$CONF_DIR/chromium-flags.conf"


# ==============================================================================
# 3. MICROSOFT EDGE CONFIGURATION
# Location: ~/.config/microsoft-edge-stable-flags.conf
# ==============================================================================
echo "[-] Configuring Edge Flags..."

cat <<EOF > "$CONF_DIR/microsoft-edge-stable-flags.conf"

--ozone-platform=wayland
--enable-wayland-ime

# Hardware Acceleration
--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiVideoDecoder,UseOzonePlatform,WebRTCPipeWireCapturer,CanvasOopRasterization
--enable-gpu-rasterization
--enable-zero-copy
--enable-native-gpu-memory-buffers
--ignore-gpu-blocklist
EOF

# Fix Permissions
chown "$REAL_USER:$REAL_USER" "$CONF_DIR/microsoft-edge-stable-flags.conf"


# ==============================================================================
# 4. ELECTRON APPS (Standard Arch Packages)
# Location: ~/.config/electron-flags.conf
# ==============================================================================
echo "[-] Configuring General Electron Flags..."

cat <<EOF > "$CONF_DIR/electron-flags.conf"
# Force Wayland (preferred over hint=auto for performance/stability)
--ozone-platform=wayland

# Merge all features into ONE line.
--enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecodeLinuxGL,VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization

# Performance: GPU Rasterization
--enable-gpu-rasterization
--enable-zero-copy
--enable-native-gpu-memory-buffers
--ignore-gpu-blocklist
EOF

# Fix Permissions
chown "$REAL_USER:$REAL_USER" "$CONF_DIR/electron-flags.conf"


# ==============================================================================
# 5. VS CODE SPECIFIC (Often ignores electron-flags.conf)
# Location: ~/.config/code-flags.conf
# ==============================================================================
echo "[-] Configuring VS Code Flags..."

# VS Code typically needs the same flags as Electron
cat <<EOF > "$CONF_DIR/code-flags.conf"
# Force Wayland
--ozone-platform=wayland
--enable-wayland-ime

# Hardware Acceleration (Intel Arc)
--enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecodeLinuxGL,VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization
--enable-gpu-rasterization
--enable-zero-copy
--enable-native-gpu-memory-buffers
--ignore-gpu-blocklist
EOF

# Fix Permissions
chown "$REAL_USER:$REAL_USER" "$CONF_DIR/code-flags.conf"


echo "=== ✅ Intel Arc Optimization Complete ==="
echo "Please REBOOT your system for /etc/environment changes to take effect."