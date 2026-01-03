#!/bin/bash
# Repository setup script
# This script calls all the individual repository setup scripts

echo "=== 🕷️ Setting up Repositories ==="

# Add artificial delay
echo "Initializing repository setup..."
sleep 2

# Run individual setup scripts
echo "[-] Setting up Chaotic AUR repository..."
sudo ../../scripts/repo/chaotic-repo.sh

echo "[-] Setting up CachyOS repository..."
sudo ../../scripts/repo/cachy-repo.sh

echo "=== ✅ Repository Setup Complete ==="