#!/bin/bash
# Toggle Mango gaming mode - adds spacing between monitors to trap cursor on main display
# Bind to Ctrl+Shift+G for quick gaming mode toggle

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/mango-gaming-mode-state"

# Normal positions (from niri config)
NORMAL_DP2_X=0
NORMAL_DP2_Y=0

# Gaming positions (adds large gaps to prevent cursor movement)
# DP-2 stays in same position
GAMING_DP2_X=0
GAMING_DP2_Y=0

# Check if wlr-randr is available
if ! command -v wlr-randr &> /dev/null; then
    notify-send "Gaming Mode" "wlr-randr not found. Please install wlr-randr to use this feature." -u critical
    exit 1
fi

if [ -f "$STATE_FILE" ]; then
    # Gaming mode is ON, switch to NORMAL
    echo "Switching to NORMAL mode - monitors adjacent"
    wlr-randr --output DP-2 --pos ${NORMAL_DP2_X},${NORMAL_DP2_Y} 2>/dev/null
    rm "$STATE_FILE"
    notify-send "Gaming Mode OFF" "Monitors restored to normal positions" -i input-gaming 2>/dev/null || notify-send "Gaming Mode OFF" "Monitors restored to normal positions"
else
    # Gaming mode is OFF, switch to GAMING
    echo "Switching to GAMING mode - cursor trapped on main monitor"
    wlr-randr --output DP-2 --pos ${GAMING_DP2_X},${GAMING_DP2_Y} 2>/dev/null
    touch "$STATE_FILE"
    notify-send "Gaming Mode ON" "Cursor confined to main monitor (DP-2)" -i input-gaming 2>/dev/null || notify-send "Gaming Mode ON" "Cursor confined to main monitor (DP-2)"
fi















