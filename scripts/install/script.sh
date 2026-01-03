#!/bin/bash
# Install setup script
# This script calls the kernel installation script

echo "=== 🕷️ Setting up Installation ==="

# Add artificial delay
echo "Initializing installation setup..."
sleep 2

# Run kernel installation
echo "[-] Installing custom kernels..."
../../scripts/install/install_kernels.sh

echo "=== ✅ Installation Setup Complete ==="