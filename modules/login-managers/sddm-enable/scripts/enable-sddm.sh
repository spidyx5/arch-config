#!/usr/bin/env bash
# Enable SDDM display manager
# Part of arch-config declarative package management

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Enabling SDDM display manager...${NC}"
echo ""

# Check if we have root privileges
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: This script must be run with sudo${NC}" >&2
  exit 1
fi

# Disable other display managers if they're enabled
for dm in gdm lightdm lxdm; do
  if systemctl is-enabled "${dm}.service" &>/dev/null; then
    echo -e "${YELLOW}Disabling ${dm} display manager...${NC}"
    systemctl disable "${dm}.service"
    echo -e "${GREEN}${dm} disabled${NC}"
  fi
done

echo ""

# Enable SDDM
if systemctl is-enabled sddm.service &>/dev/null; then
  echo -e "${YELLOW}SDDM is already enabled${NC}"
else
  echo -e "${BLUE}Enabling SDDM service...${NC}"
  systemctl enable sddm.service
  echo -e "${GREEN}SDDM enabled${NC}"
fi

echo ""
echo -e "${GREEN}SDDM configuration complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  - Reboot your system to use SDDM"
echo "  - Or manually start SDDM: sudo systemctl start sddm.service"
echo ""
