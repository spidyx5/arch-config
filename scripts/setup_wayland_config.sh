#!/bin/bash

# Ensure sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit
fi

# Detect the Real User (Spidy) to fix file permissions later
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd $REAL_USER | cut -d: -f6)

echo "=== 🚀 Configuring Wayland Apps & Environment (Spidy Custom Profile) ==="

# ==============================================================================
# 1. GLOBAL ENVIRONMENT VARIABLES
# ==============================================================================
echo "[-] Updating /etc/environment..."

# Function to safely append if not exists
add_env_var() {
    local var_name=$1
    local var_line=$2
    if ! grep -q "^$var_name" /etc/environment; then
        echo "$var_line" | tee -a /etc/environment > /dev/null
        echo "    + Added: $var_name"
    fi
}

# --- Hardware Acceleration (Forced) ---
# Explicitly requested by user.
add_env_var "LIBVA_DRIVER_NAME" "LIBVA_DRIVER_NAME=iHD"
add_env_var "LIBGL_ALWAYS_SOFTWARE" "LIBGL_ALWAYS_SOFTWARE=0"
add_env_var "ENABLE_VAAPI" "ENABLE_VAAPI=1"
add_env_var "ENABLE_VDPAU" "ENABLE_VDPAU=1"
# Critical for Intel Arc stability in OBS/Discord:
add_env_var "VAAPI_DISABLE_ENCODER_CHECKING" "VAAPI_DISABLE_ENCODER_CHECKING=1"

# --- Wayland Core ---
add_env_var "EGL_PLATFORM" "EGL_PLATFORM=wayland"
# Forced Vulkan Renderer (User Request) - Uses Vulkan for the desktop compositor
add_env_var "WLR_RENDERER" "WLR_RENDERER=vulkan"


# --- Toolkits (Qt/GTK/Java) ---
add_env_var "QT_QPA_PLATFORM" "QT_QPA_PLATFORM=wayland;xcb"
add_env_var "QT_QPA_PLATFORMTHEME" "QT_QPA_PLATFORMTHEME=qt6ct"
add_env_var "QT_WAYLAND_DISABLE_WINDOWDECORATION" "QT_WAYLAND_DISABLE_WINDOWDECORATION=1"
add_env_var "SDL_VIDEODRIVER" "SDL_VIDEODRIVER=wayland"
add_env_var "CLUTTER_BACKEND" "CLUTTER_BACKEND=wayland"
add_env_var "GDK_BACKEND" "GDK_BACKEND=wayland,x11"
add_env_var "ECORE_EVAS_ENGINE" "ECORE_EVAS_ENGINE=wayland-egl"
add_env_var "ELM_ENGINE" "ELM_ENGINE=wayland_egl"
add_env_var "_JAVA_AWT_WM_NONREPARENTING" "_JAVA_AWT_WM_NONREPARENTING=1"

# --- Electron/Browsers ---
add_env_var "MOZ_ENABLE_WAYLAND" "MOZ_ENABLE_WAYLAND=1"
add_env_var "MOZ_DBUS_REMOTE" "MOZ_DBUS_REMOTE=1"
add_env_var "ELECTRON_OZONE_PLATFORM_HINT" "ELECTRON_OZONE_PLATFORM_HINT=wayland"

# ==============================================================================
# 2. CHROMIUM CONFIGURATION
# Location: ~/.config/chromium-flags.conf
# ==============================================================================
echo "[-] Configuring Chromium Flags..."
CONF_DIR="$USER_HOME/.config"
mkdir -p "$CONF_DIR"

cat <<EOF > "$CONF_DIR/chromium-flags.conf"
# === Spidy Chromium Optimization ===

# Force Wayland
--ozone-platform-hint=auto
--ozone-platform=wayland

# GPU Acceleration (Intel Arc Optimized)
--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiVideoDecoder,CanvasOopRasterization,UseOzonePlatform
--enable-gpu-rasterization
--enable-zero-copy
--enable-hardware-overlays
--enable-vulkan

# Memory Saving (Low RAM)
--process-per-site
--renderer-process-limit=2

# Smoothness & Privacy
--enable-smooth-scrolling
--ignore-gpu-blocklist
--enable-drdc
--no-default-browser-check
EOF

# Fix Permissions (Give ownership back to Spidy)
chown "$REAL_USER:$REAL_USER" "$CONF_DIR/chromium-flags.conf"

# ==============================================================================
# 3. MICROSOFT EDGE CONFIGURATION
# Location: ~/.config/microsoft-edge-stable-flags.conf
# ==============================================================================
echo "[-] Configuring Edge Flags..."

cat <<EOF > "$CONF_DIR/microsoft-edge-stable-flags.conf"
# === Spidy Edge Optimization ===

# Wayland
--ozone-platform-hint=auto
--ozone-platform=wayland
--enable-wayland-ime

# Hardware Acceleration
--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoDecoder,VaapiVideoEncoder,UseOzonePlatform,WebRTCPipeWireCapturer
--enable-zero-copy
--ignore-gpu-blocklist

# Low RAM Tweaks
--process-per-site
--renderer-process-limit=2
EOF

# Fix Permissions
chown "$REAL_USER:$REAL_USER" "$CONF_DIR/microsoft-edge-stable-flags.conf"

# ==============================================================================
# 4. ELECTRON APPS (VS Code / Obsidian / Discord)
# ==============================================================================
echo "[-] Configuring General Electron Flags..."

cat <<EOF > "$CONF_DIR/electron-flags.conf"
# Force Wayland (preferred over hint=auto for performance/stability)
--ozone-platform=wayland

# Merge all features into ONE line.
# Added: VaapiVideoDecodeLinuxGL (Video Decode), VaapiVideoEncoder (Screen Share), CanvasOopRasterization
--enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecodeLinuxGL,VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization

# Performance: GPU Rasterization and Memory Tweaks
--enable-gpu-rasterization
--enable-zero-copy
--enable-native-gpu-memory-buffers
--ignore-gpu-blocklist
EOF

# Fix Permissions
chown "$REAL_USER:$REAL_USER" "$CONF_DIR/electron-flags.conf"

echo "=== ✅ Wayland Apps Optimized (Custom) ==="
echo "Enabled: iHD Driver, Vulkan Renderer, No Software GL."
