#!/bin/bash
# Program setup script
# This script calls all the individual program setup scripts

echo "=== 🕷️ Setting up Programs ==="

# Add artificial delay
echo "Initializing program setup..."
sleep 2

# Run individual setup scripts
echo "[-] Setting up XDG applications..."
../../scripts/program/setup_xdg.sh

echo "[-] Setting up Keyd..."
sudo ../../scripts/program/setup_keyd.sh

echo "[-] Setting up doas..."
sudo ../../scripts/program/doas.sh

echo "[-] Setting up Virtualization..."
sudo ../../scripts/program/setup_virt.sh

echo "[-] Setting up OpenTabletDriver..."
sudo ../../scripts/program/opentabletdriver_setup.sh

echo "=== ✅ Program Setup Complete ==="