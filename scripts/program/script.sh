#!/bin/bash
# Program setup script
# This script calls all the individual program setup scripts

echo "=== 🕷️ Setting up Programs ==="

# Add artificial delay
echo "Initializing program setup..."
sleep 2

# Run individual setup scripts
echo "[-] Setting up XDG applications..."
./setup_xdg.sh

echo "[-] Setting up Keyd..."
sudo ./setup_keyd.sh

echo "[-] Setting up Virtualization..."
sudo ./setup_virt.sh

echo "[-] Setting up OpenTabletDriver..."
./opentabletdriver_setup.sh

echo "=== ✅ Program Setup Complete ==="