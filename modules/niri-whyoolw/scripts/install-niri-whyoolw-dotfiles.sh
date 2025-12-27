#!/usr/bin/env bash
# Post-install hook for niri-whyoolw module
# Dotfiles are now handled by dcli's symlink system
# This script only handles additional configuration that can't be symlinked

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine the user (handles both sudo and non-sudo cases)
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="/home/${TARGET_USER}"
CONFIG_DIR="${TARGET_HOME}/.config"
ARCH_CONFIG_DIR="${ARCH_CONFIG_DIR:-${TARGET_HOME}/.config/arch-config}"

echo -e "${BLUE}Configuring Niri-whyoolw environment...${NC}"
echo ""
echo -e "${YELLOW}Note: Dotfiles are now managed via symlinks by dcli${NC}"
echo ""

echo -e "${GREEN}Niri-whyoolw environment configuration complete!${NC}"
echo ""
echo -e "${BLUE}Dotfiles are symlinked from arch-config/modules/niri-whyoolw/dotfiles/${NC}"
echo ""
echo -e "${BLUE}To apply changes:${NC}"
echo "  - Reload Niri: 'niri msg action reload-config'"
echo "  - For full effect, log out and log back in"
echo ""