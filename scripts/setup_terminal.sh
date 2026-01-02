#!/bin/bash

# ==============================================================================
# SPIDY FISH SHELL ULTIMATE SETUP
# ==============================================================================

set -e

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (sudo)"
  exit 1
fi

# 2. User Detection
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd $REAL_USER | cut -d: -f6)
FISH_CONFIG_DIR="$USER_HOME/.config/fish"
FISH_CONFIG_FILE="$FISH_CONFIG_DIR/config.fish"

echo "=== 🕷️ Setting up Fish Shell for user: $REAL_USER ==="

# ==============================================================================
# STEP 1: INSTALL PACKAGES
# ==============================================================================
echo "[-] Installing required tools..."

PACKAGES=(
    "fish"
    "starship"
    "zoxide"
    "fzf"
    "eza"
    "bat"
    "ripgrep"
    "fd"
    "btop"
    "helix"
    "carapace" 
)

# Attempt install. If carapace fails (sometimes AUR only), we continue.
pacman -S --needed --noconfirm "${PACKAGES[@]}" || echo "⚠️ Warning: Some packages failed. Ensure 'carapace' is installed via AUR if not found."

# ==============================================================================
# STEP 2: BACKUP EXISTING CONFIG
# ==============================================================================
if [ -f "$FISH_CONFIG_FILE" ]; then
    echo "[-] Backing up existing config to config.fish.bak..."
    mv "$FISH_CONFIG_FILE" "$FISH_CONFIG_FILE.bak"
fi

mkdir -p "$FISH_CONFIG_DIR"

# ==============================================================================
# STEP 3: WRITE CONFIG.FISH
# ==============================================================================
echo "[-] Generating optimized config.fish..."

# We write the file as the REAL_USER to ensure permissions are correct
sudo -u "$REAL_USER" tee "$FISH_CONFIG_FILE" > /dev/null << 'EOF'
# ==============================================================================
# SPIDY FISH CONFIG
# ==============================================================================

# Only run this in interactive mode (prevents errors in scripts)
if status is-interactive

    # --- 1. Environment Variables ---
    # Disable the default welcome message
    set -g fish_greeting ""
    
    # Set Editor to Helix
    set -gx EDITOR helix
    
    # Bat Theme (Dracula)
    # Note: Run 'bat --list-themes' to verify availability. 
    set -gx BAT_THEME "Dracula"
    
    # FZF Defaults (Dracula-ish colors)
    set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"

    # --- 2. Tool Initializations ---
    
    # Starship Prompt
    starship init fish | source

    # Zoxide (Smarter cd)
    # --cmd cd: This replaces the standard 'cd' command with zoxide
    zoxide init fish --cmd cd | source

    # Carapace (Completions)
    carapace _carapace | source

    # --- 3. Aliases (Replacements) ---

    # Navigation
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
    
    # Eza (Better ls)
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'
    alias la='eza -la --icons --group-directories-first'
    alias tree='eza --tree --icons'
    
    # Bat (Better cat)
    alias cat='bat'
    
    # Ripgrep (Better grep)
    alias grep='rg'
    
    # Fd (Better find)
    alias find='fd'
    
    # Btop (Better top)
    alias top='btop'
    
    # Helix
    alias hx='helix'
    
    alias fr="fresh'
    alias tp='topgrade'
    # Safety first (Interactive)
    alias cp='cp -i'
    alias mv='mv -i'
    alias rm='rm -i'
    
    # System Info
    alias df='df -h'
    alias free='free -h'

    # --- 4. Abbreviations (Auto-expanding) ---
    # Type 'pac' then SPACE, it becomes 'sudo pacman' automatically.
    
    abbr --add pac 'sudo pacman'
    abbr --add paci 'sudo pacman -S'
    abbr --add pacr 'sudo pacman -Rns'   # Remove pkg + unused deps
    abbr --add pacu 'sudo pacman -Syu'   # Update system
    abbr --add pacs 'pacman -Ss'         # Search packages
    abbr --add pacq 'pacman -Qi'         # Query package info
    abbr --add unlock 'sudo rm /var/lib/pacman/db.lck'
    
    # Git shortcuts (Optional but recommended)
    abbr --add g 'git'
    abbr --add ga 'git add'
    abbr --add gc 'git commit -m'
    abbr --add gp 'git push'
    abbr --add gl 'git pull'
    
end
EOF

# ==============================================================================
# STEP 4: PERMISSIONS & CLEANUP
# ==============================================================================
# Ensure ownership is correct
chown "$REAL_USER:$REAL_USER" "$FISH_CONFIG_FILE"

echo "=== ✅ Fish Setup Complete ==="
echo "1. Run 'fish' to enter your new shell."
echo "2. If prompts look weird, install a Nerd Font (e.g., ttf-jetbrains-mono-nerd)."
echo "3. Abbreviations work by typing the key (e.g., 'pac') and hitting SPACE."