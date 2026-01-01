#!/bin/bash

# Ensure sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit
fi

# Detect Real User
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "=== 🐚 Setting up Modern Shells (Fish & Nushell) ==="

# ==============================================================================
# 1. INSTALL DEPENDENCIES
# ==============================================================================
echo "[-] Installing Shells & Modern Tools..."
# carapace-bin is usually in AUR or chaotic-aur (CachyOS has it)
# If carapace-bin fails, try carapace
pacman -S --needed --noconfirm fish nushell starship zoxide eza bat ripgrep fd fzf helix
# Try to install carapace (Shell completions)
if ! pacman -Qi carapace-bin &>/dev/null && ! pacman -Qi carapace &>/dev/null; then
    echo "    Attempting to install carapace..."
    pacman -S --noconfirm carapace || echo "Warning: Carapace not found in repos."
fi

# ==============================================================================
# 2. SHARED STARSHIP CONFIGURATION
# ==============================================================================
echo "[-] Configuring Starship (Prompt)..."
STARSHIP_DIR="$USER_HOME/.config"
mkdir -p "$STARSHIP_DIR"

cat <<EOF > "$STARSHIP_DIR/starship.toml"
# Spidy Modern Starship Config

add_newline = true

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = false
style = "bold cyan"

[git_branch]
symbol = " "
style = "bold purple"

[git_status]
style = "bold red"

[package]
symbol = " "
disabled = true

[nodejs]
symbol = " "

[rust]
symbol = " "

[golang]
symbol = " "

[cmd_duration]
min_time = 2000
style = "bold yellow"
EOF

chown -R "$REAL_USER:$REAL_USER" "$STARSHIP_DIR/starship.toml"

# ==============================================================================
# 3. FISH SHELL CONFIGURATION (Primary Focus)
# ==============================================================================
echo "[-] Configuring Fish Shell..."
FISH_CONFIG_DIR="$USER_HOME/.config/fish"
mkdir -p "$FISH_CONFIG_DIR/conf.d"
mkdir -p "$FISH_CONFIG_DIR/functions"

# --- Main Config ---
cat <<EOF > "$FISH_CONFIG_DIR/config.fish"
# === Spidy Fish Config ===

# 1. Environment Variables
set -gx EDITOR hx
set -gx VISUAL hx
set -gx PAGER bat
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"

# Disable the "Welcome to Fish" message
set -g fish_greeting

# 2. Path (Add ~/.local/bin and Cargo)
fish_add_path "$USER_HOME/.local/bin"
fish_add_path "$USER_HOME/.cargo/bin"

# 3. Interactive Session Initializations
if status is-interactive
    # Starship Prompt
    starship init fish | source

    # Zoxide (Smarter 'cd')
    zoxide init fish | source

    # Carapace (Completions)
    # Prevents error if carapace isn't installed
    if type -q carapace
        set -x CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense' # optional
        mkdir -p ~/.config/fish/completions
        carapace --list | awk '{print \$1}' | xargs -I{} touch ~/.config/fish/completions/{}.fish # workaround
        carapace _carapace | source
    end
end

# 4. Aliases & Abbreviations

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Eza (Better ls)
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias tree='eza --tree --icons'

# Tools
alias cat='bat'
alias grep='rg'
alias find='fd'
alias top='htop'

# Package Management (Arch)
# 'abbr' is better than alias in Fish (expands when you type space)
abbr -a pac 'sudo pacman'
abbr -a paci 'sudo pacman -S'
abbr -a pacr 'sudo pacman -Rns'
abbr -a pacu 'sudo pacman -Syu'
abbr -a pacs 'pacman -Ss'
abbr -a pacq 'pacman -Qi'
abbr -a unlock 'sudo rm /var/lib/pacman/db.lck'

# System
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias df='df -h'
alias free='free -h'

# Editor
alias hx='helix'
alias vim='helix'
alias nano='helix'
EOF

# Fix Ownership
chown -R "$REAL_USER:$REAL_USER" "$FISH_CONFIG_DIR"

# ==============================================================================
# 4. NUSHELL CONFIGURATION (Modern v0.90+)
# ==============================================================================
echo "[-] Configuring Nushell..."
NU_CONFIG_DIR="$USER_HOME/.config/nushell"
mkdir -p "$NU_CONFIG_DIR"

# --- env.nu ---
cat <<EOF > "$NU_CONFIG_DIR/env.nu"
# Env Config for Spidy

\$env.STARSHIP_SHELL = "nu"

def create_left_prompt [] {
    starship prompt --cmd-duration \$env.CMD_DURATION_MS $'--status=(\$env.LAST_EXIT_CODE)'
}

\$env.PROMPT_COMMAND = { || create_left_prompt }
\$env.PROMPT_COMMAND_RIGHT = ""

\$env.PROMPT_INDICATOR = { || "" }
\$env.PROMPT_INDICATOR_VI_INSERT = { || ": " }
\$env.PROMPT_INDICATOR_VI_NORMAL = { || "> " }
\$env.PROMPT_MULTILINE_INDICATOR = { || "::: " }

# Environment Variables
\$env.EDITOR = "hx"
\$env.VISUAL = "hx"
\$env.PAGER = "bat"

# Path
\$env.PATH = (\$env.PATH | split row (char esep) | prepend [
    ($USER_HOME | path join ".cargo" "bin")
    ($USER_HOME | path join ".local" "bin")
])

# Directories
\$env.XDG_CONFIG_HOME = ($USER_HOME | path join ".config")
EOF

# --- config.nu ---
cat <<EOF > "$NU_CONFIG_DIR/config.nu"
# Config for Spidy

\$env.config = {
    show_banner: false
    ls: { use_ls_colors: true }
    rm: { always_trash: false }

    # Completions
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
        external: {
            enable: true
            max_results: 100
            completer: {|spans|
                carapace \$spans.0 nushell \$spans | from json
            }
        }
    }
}

# --- Aliases ---
alias ll = eza -l --icons --group-directories-first
alias la = eza -la --icons --group-directories-first
alias ls = eza --icons --group-directories-first
alias tree = eza --tree --icons

alias cat = bat
alias grep = rg
alias find = fd
alias top = htop

alias .. = cd ..
alias ... = cd ../..
alias .... = cd ../../..

# Pacman
alias pac = sudo pacman
alias paci = sudo pacman -S
alias pacr = sudo pacman -Rns
alias pacu = sudo pacman -Syu
alias pacs = pacman -Ss
alias pacq = pacman -Qi

alias cp = cp -i
alias mv = mv -i
alias rm = rm -i

alias hx = helix
alias vim = helix
alias nano = helix

# --- Initializations ---
# We verify if tools exist before initializing to prevent errors

# Zoxide
if (which zoxide | is-empty) == false {
    zoxide init nushell | save -f ~/.zoxide.nu
    source ~/.zoxide.nu
}

# Starship
if (which starship | is-empty) == false {
    mkdir ~/.cache/starship
    starship init nu | save -f ~/.cache/starship/init.nu
    source ~/.cache/starship/init.nu
}
EOF

# Fix Ownership
chown -R "$REAL_USER:$REAL_USER" "$NU_CONFIG_DIR"
# Create cache dir for Nu if missing so the script doesn't error on first run
mkdir -p "$USER_HOME/.cache/starship"
chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.cache"

echo "=== ✅ Shell Setup Complete ==="
echo "To switch defaults, run one of these as your normal user:"
echo "  chsh -s /usr/bin/fish"
echo "  chsh -s /usr/bin/nu"