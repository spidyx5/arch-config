#!/bin/bash
# Master setup script for packages module
# This script calls all individual setup scripts in the correct order

set -e  # Exit on any error

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo"
    echo "Usage: sudo $0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Starting Master Setup Script ==="
echo ""

# System setup scripts
echo "📦 Running system setup scripts..."
bash "$SCRIPT_DIR/apply_system_config.sh"
bash "$SCRIPT_DIR/update_limine.sh"
bash "$SCRIPT_DIR/setup_services.sh"
bash "$SCRIPT_DIR/setup_keyd.sh"
bash "$SCRIPT_DIR/optimize_makepkg.sh"
bash "$SCRIPT_DIR/setup_hardware.sh"
bash "$SCRIPT_DIR/setup_audio.sh"
bash "$SCRIPT_DIR/setup_xdg.sh"
bash "$SCRIPT_DIR/install_kernels.sh"
bash "$SCRIPT_DIR/setup_wayland_config.sh"  # Fixed: was "base" instead of "bash"

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
