#!/bin/bash
# Toggle Niri gaming mode - adds spacing between monitors to trap cursor on main display
# Bind to Ctrl+Shift+G for quick gaming mode toggle

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-gaming-mode-state"

# Normal positions (from your config)
NORMAL_DP2_X=0
NORMAL_DP2_Y=0

# Gaming positions (adds large gaps to prevent cursor movement)
# DP-2 stays in same position
GAMING_DP2_X=0
GAMING_DP2_Y=0

# Check if niri is available
if ! command -v niri &> /dev/null; then
    notify-send "Gaming Mode" "niri not found. Please ensure niri is running." -u critical
    exit 1
fi

if [ -f "$STATE_FILE" ]; then
    # Gaming mode is ON, switch to NORMAL
    echo "Switching to NORMAL mode - monitors adjacent"
    niri msg output DP-2 position set -- $NORMAL_DP2_X $NORMAL_DP2_Y 2>/dev/null
    rm "$STATE_FILE"
    notify-send "Gaming Mode OFF" "Monitors restored to normal positions" -i input-gaming 2>/dev/null || notify-send "Gaming Mode OFF" "Monitors restored to normal positions"
else
    # Gaming mode is OFF, switch to GAMING
    echo "Switching to GAMING mode - cursor trapped on main monitor"
    niri msg output DP-2 position set -- $GAMING_DP2_X $GAMING_DP2_Y 2>/dev/null
    touch "$STATE_FILE"
    notify-send "Gaming Mode ON" "Cursor confined to main monitor (DP-2)" -i input-gaming 2>/dev/null || notify-send "Gaming Mode ON" "Cursor confined to main monitor (DP-2)"
fi















