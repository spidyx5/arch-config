#!/bin/bash
# System setup script
# This script calls all the individual system setup scripts

echo "=== 🕷️ Setting up System ==="

# Add artificial delay
echo "Initializing system setup..."
sleep 2

# Run individual setup scripts
echo "[-] Applying system configuration..."
sudo ../../scripts/system/apply_system_config.sh

echo "[-] Setting up hardware..."
sudo ../../scripts/system/setup_hardware.sh

echo "[-] Setting up audio..."
sudo ../../scripts/system/setup_audio.sh

echo "[-] Setting up network..."
sudo ../../scripts/system/setup_network.sh

echo "[-] Setting up services..."
sudo ../../scripts/system/setup_services.sh

echo "[-] Setting up Wayland configuration..."
sudo ../../scripts/system/setup_wayland_config.sh

echo "=== ✅ System Setup Complete ==="