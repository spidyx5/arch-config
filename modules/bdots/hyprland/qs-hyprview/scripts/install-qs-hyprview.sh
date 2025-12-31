#!/usr/bin/env bash
# Install QS Hyprview workspace overview for Hyprland
# Part of arch-config declarative package management

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

QUICKSHELL_CONFIG_DIR="${HOME}/.config/quickshell"
QS_HYPRVIEW_DIR="${QUICKSHELL_CONFIG_DIR}/qs-hyprview"
REPO_URL="https://github.com/dwilliam62/qs-hyprview.git"

echo -e "${BLUE}Installing QS Hyprview...${NC}"
echo ""

# Create quickshell config directory if it doesn't exist
if [ ! -d "$QUICKSHELL_CONFIG_DIR" ]; then
  echo -e "${BLUE}Creating quickshell config directory: $QUICKSHELL_CONFIG_DIR${NC}"
  mkdir -p "$QUICKSHELL_CONFIG_DIR"
fi

# Clone or update the repository
if [ -d "$QS_HYPRVIEW_DIR" ]; then
  echo -e "${YELLOW}QS Hyprview already exists, updating...${NC}"
  cd "$QS_HYPRVIEW_DIR"
  git pull origin main || {
    echo -e "${RED}Failed to update repository${NC}" >&2
    exit 1
  }
else
  echo -e "${BLUE}Cloning QS Hyprview repository...${NC}"
  git clone "$REPO_URL" "$QS_HYPRVIEW_DIR" || {
    echo -e "${RED}Failed to clone repository${NC}" >&2
    exit 1
  }
fi

echo ""
echo -e "${GREEN}✓ QS Hyprview installed successfully!${NC}"
echo ""
echo -e "${BLUE}Installation location:${NC}"
echo "  $QS_HYPRVIEW_DIR"
echo ""
echo -e "${BLUE}Usage:${NC}"
echo "  The keybind has been configured to use 'masonry' layout."
echo "  Press SUPER+X to toggle the workspace overview."
echo ""
echo -e "${BLUE}Available layouts:${NC}"
echo "  smartgrid, justified, masonry, bands, hero, spiral,"
echo "  satellite, staggered, columnar, random"
echo ""
echo -e "${BLUE}Controls:${NC}"
echo "  • Type to filter windows by title/class/app ID"
echo "  • Arrow keys to navigate thumbnails"
echo "  • Tab/Shift+Tab for sequential navigation"
echo "  • Enter to activate selected window"
echo "  • Middle click to close window"
echo "  • Esc to close overview"
echo ""
echo -e "${YELLOW}Note:${NC} The QS Hyprview daemon will start automatically with Hyprland."
echo ""
