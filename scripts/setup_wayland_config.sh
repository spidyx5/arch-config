#!/bin/bash

echo "=== Configuring Wayland Apps & Environment ==="

# ==============================================================================
# 1. GLOBAL ENVIRONMENT VARIABLES
# Matches home.sessionVariables & hardware video acceleration vars
# ==============================================================================
echo "Setting Global Wayland Environment Variables..."

cat <<EOF | sudo tee /etc/environment
# --- Hardware Acceleration ---
LIBVA_DRIVER_NAME=iHD
LIBVA_MESSAGING_LEVEL=1
LIBGL_ALWAYS_SOFTWARE=0
ENABLE_VAAPI=1
ENABLE_VDPAU=1
VAAPI_DISABLE_ENCODER_CHECKING=1
EGL_PLATFORM=wayland
WLR_RENDERER=vulkan
WLR_NO_HARDWARE_CURSORS=1

# --- Toolkit Backends ---
# Force Wayland for Qt, SDL, Clutter, Java
QT_QPA_PLATFORM=wayland;xcb
QT_WAYLAND_DISABLE_WINDOWDECORATION=1
QT_QPA_PLATFORMTHEME=qt6ct
SDL_VIDEODRIVER=wayland
CLUTTER_BACKEND=wayland
ECORE_EVAS_ENGINE=wayland-egl
ELM_ENGINE=wayland_egl
GDK_BACKEND=wayland,x11
_JAVA_AWT_WM_NONREPARENTING=1

# --- Browser/Electron Specific ---
MOZ_ENABLE_WAYLAND=1
MOZ_DBUS_REMOTE=1
ELECTRON_OZONE_PLATFORM_HINT=wayland
EOF

# ==============================================================================
# 2. CHROMIUM CONFIGURATION
# Matches xdg.configFile."chromium-flags.conf"
# Arch Chromium reads ~/.config/chromium-flags.conf automatically.
# ==============================================================================
echo "Configuring Chromium Flags..."
mkdir -p "$HOME/.config"

cat <<EOF > "$HOME/.config/chromium-flags.conf"
# Wayland Support
--ozone-platform=wayland

# GPU & Video
--use-gl=desktop
--ignore-gpu-blocklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-vulkan
--disable-gpu-driver-bug-workarounds
--enable-features=UseOzonePlatform,VaapiVideoEncoder,VaapiVideoDecoder,CanvasOopRasterization,VaapiIgnoreDriverChecks,OverlayScrollbar,ParallelDownloading

# Hardware Acceleration
--enable-hardware-overlays
--enable-accelerated-video-decode
--enable-accelerated-video-encode
--enable-accelerated-mjpeg-decode
--enable-oop-rasterization
--enable-raw-draw
--enable-webgl-developer-extensions
--enable-accelerated-2d-canvas
--enable-direct-composition
--enable-drdc
--enable-gpu-compositing

# Performance
--enable-media-router
--enable-smooth-scrolling

# Privacy
--disable-search-engine-collection
--extension-mime-request-handling=always-prompt-for-install
--fingerprinting-canvas-image-data-noise
--fingerprinting-canvas-measuretext-noise
--fingerprinting-client-rects-noise
--popups-to-tabs
--force-punycode-hostnames
--show-avatar-button=incognito-and-guest

# Misc
--no-default-browser-check
--no-pings
EOF

# ==============================================================================
# 3. MICROSOFT EDGE CONFIGURATION
# Matches microsoft-edge.override arguments
# Edge on Linux reads ~/.config/microsoft-edge-stable-flags.conf
# ==============================================================================
echo "Configuring Edge Flags..."

cat <<EOF > "$HOME/.config/microsoft-edge-stable-flags.conf"
--ignore-gpu-blocklist
--enable-zero-copy
--ozone-platform-hint=auto
--ozone-platform=wayland
--enable-wayland-ime
--process-per-site
--enable-features=WebUIDarkMode,UseOzonePlatform,VaapiVideoDecodeLinuxGL,VaapiVideoDecoder,WebRTCPipeWireCapturer,WaylandWindowDecorations
EOF
echo "Wayland Apps configuration applied."
