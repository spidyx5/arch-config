# Arch Config Setup

This repository contains configuration files for Arch Linux using `dcli` for dotfile management.

## Prerequisites

- **OS:** Arch Linux (fresh install recommended)
- **Packages:** `git` (`sudo pacman -S git`)
- **Hostname:** Ensure your machine's hostname matches the filename in `hosts/` (your machine must be named `spidy`).

## Installation

### 1. Install `dcli`

```bash
# Clone the dcli repository
git clone https://gitlab.com/theblackdon/dcli.git

# Enter the directory
cd dcli

# Run the installer
./install.sh

# Verify installation
dcli --help
```

### 2. Clone this repository

```bash
git clone https://github.com/spidyx5/arch-config.git ~/.config/arch-config
```

### 3. Sync and update configurations

```bash
dcli sync
dcli update
```

## Usage

After installation, your dotfiles and configurations should be applied. Refer to the `modules/` and `hosts/` directories for specific configurations.