#!/bin/bash
# System setup script
# This script calls all the individual system setup scripts

echo "=== 🕷️ Setting up System ==="

# Add artificial delay
echo "Initializing system setup..."
sleep 2

# Run individual setup scripts
echo "[-] Applying system configuration..."
sudo ./apply_system_config.sh

echo "[-] Setting up hardware..."
sudo ./setup_hardware.sh

echo "[-] Setting up audio..."
sudo ./setup_audio.sh

echo "[-] Setting up network..."
sudo ./setup_network.sh

echo "[-] Setting up services..."
sudo ./setup_services.sh

echo "[-] Setting up Wayland configuration..."
sudo ./setup_wayland_config.sh

echo "=== ✅ System Setup Complete ==="