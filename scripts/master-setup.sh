#!/bin/bash
# Master setup script for packages module
# This script calls all individual setup scripts in the correct order

set -e  # Exit on any error

echo "=== Starting Master Setup Script ==="
echo ""

# System setup scripts
echo "📦 Running system setup scripts..."
bash ./scripts/apply_system_config.sh
bash ./scripts/update_limine.sh
bash ./scripts/setup_services.sh
bash ./scripts/setup_keyd.sh
bash ./scripts/optimize_makepkg.sh
bash ./scripts/setup_hardware.sh
bash ./scripts/setup_audio.sh
bash ./scripts/setup_xdg.sh
bash ./scripts/install_kernels.sh
bash ./scripts/setup_wayland_config.sh  # Fixed: was "base" instead of "bash"

# Programs setup scripts
echo "📦 Running programs setup scripts..."
bash ./scripts/opentabletdriver_setup.sh
bash ./scripts/browser_config.sh

# Development scripts
echo "📦 Running development setup scripts..."
bash ./scripts/setup_terminal.sh
bash ./scripts/setup_virt.sh

# Repository scripts
echo "📦 Running repository setup scripts..."
bash ./scripts/chaotic-repo.sh
bash ./scripts/cachy-repo.sh

echo ""
echo "✅ Master setup script completed successfully!"
echo "All individual setup scripts have been executed."
