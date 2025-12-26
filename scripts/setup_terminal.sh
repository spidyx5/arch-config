#!/bin/bash

echo "=== Configuring Terminal Environment (Nushell + Starship) ==="

# ==============================================================================
# 1. NUSHELL CONFIGURATION
# ==============================================================================
echo "Configuring Nushell..."

# Create config directory
NU_CONFIG_DIR="$HOME/.config/nushell"
mkdir -p "$NU_CONFIG_DIR"

# Write config.nu
cat <<EOF > "$NU_CONFIG_DIR/config.nu"
# ==============================================================================
# Nushell Configuration (Migrated from NixOS)
# ==============================================================================

# Load environment
source ~/.config/nushell/env.nu

# Starship Prompt
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu

# Zoxide
zoxide init nushell | save -f ~/.zoxide.nu

# Carapace (Shell completion)
carapace _carapace nushell | save -f ~/.cache/carapace/init.nu

# Load all completions
source ~/.cache/starship/init.nu
source ~/.zoxide.nu
source ~/.cache/carapace/init.nu

# ==============================================================================
# ALIASES (From your NixOS shellAliases)
# ==============================================================================

# Navigation
alias ll = ls -l
alias la = ls -a
alias lla = ls -la
alias .. = cd ..
alias ... = cd ../..
alias .... = cd ../../..

# Git
alias gs = git status
alias ga = git add
alias gc = git commit
alias gp = git push
alias gl = git log --oneline
alias gd = git diff
alias gds = git diff --staged
alias gb = git branch
alias gco = git checkout
alias gcb = git checkout -b
alias gm = git merge
alias gr = git rebase
alias gst = git stash
alias gsp = git stash pop

# System
alias df = df -h
alias du = du -h
alias free = free -h
alias ps = ps aux
alias top = htop
alias cat = bat
alias grep = rg
alias find = fd
alias ls = eza --icons
alias tree = eza --tree --icons

# Nix (if you have it)
alias nix-shell = nix-shell --command nu
alias nix-develop = nix develop --command nu

# Package management
alias pac = sudo pacman
alias paci = sudo pacman -S
alias pacr = sudo pacman -Rns
alias pacu = sudo pacman -Syu
alias pacs = pacman -Ss
alias pacq = pacman -Qi
alias pacl = pacman -Ql

# File operations
alias cp = cp -i
alias mv = mv -i
alias rm = rm -i
alias mkdir = mkdir -p

# Network
alias ping = ping -c 4
alias wget = wget -c
alias curl = curl -L

# Development
alias hx = helix
alias fm = yazi
alias lg = lazygit

# ==============================================================================
# SETTINGS
# ==============================================================================

# Completion
\$env.config = {
  show_banner: false
  edit_mode: vi
  completion_mode: circular
  history: {
    max_size: 10000
    sync_on_enter: true
    file_format: "plaintext"
  }
  pager: {
    page: (which less | get path | first)
  }
  table: {
    mode: rounded
    index_mode: always
    show_empty: true
    padding: { left: 1, right: 1 }
    trim: {
      methodology: wrapping
      wrapping_try_keep_words: true
      truncating_suffix: "..."
    }
    header_on_separator: false
  }
  explore: {
    status_bar_background: { fg: "#1e1e2e", bg: "#cdd6f4" }
    command_bar_text: { fg: "#cdd6f4" }
    split_line: "#cdd6f4"
    status: {
      error: { fg: "#1e1e2e", bg: "#eba0ac" }
      warn: { fg: "#1e1e2e", bg: "#f9e2af" }
      info: { fg: "#1e1e2e", bg: "#89b4fa" }
    }
    selected: { bg: "#cdd6f4", fg: "#1e1e2e" }
    labels: { bg: "#6c7086", fg: "#cdd6f4" }
    separator: "#cdd6f4"
  }
}

# ==============================================================================
# HOOKS
# ==============================================================================

# Directory change hook (zoxide)
def --env __zoxide_hook [] {
    zoxide add (pwd | path expand)
}

\$env.config = (\$env.config | upsert hooks {
  pre_prompt: [{ \$__zoxide_hook }]
})
EOF

# Write env.nu
cat <<EOF > "$NU_CONFIG_DIR/env.nu"
# ==============================================================================
# Nushell Environment (Migrated from NixOS)
# ==============================================================================

# Editor
\$env.EDITOR = "hx"
\$env.VISUAL = "hx"

# Pager
\$env.PAGER = "bat"

# Language
\$env.LANG = "en_US.UTF-8"
\$env.LC_ALL = "en_US.UTF-8"

# XDG Base Directory
\$env.XDG_CONFIG_HOME = (\$env.HOME | path join ".config")
\$env.XDG_DATA_HOME = (\$env.HOME | path join ".local" "share")
\$env.XDG_CACHE_HOME = (\$env.HOME | path join ".cache")

# Path
\$env.PATH = (\$env.PATH | split row (char esep) | prepend [
  (\$env.HOME | path join ".cargo" "bin")
  (\$env.HOME | path join ".local" "bin")
  "/usr/local/bin"
  "/usr/bin"
  "/bin"
])

# Starship
\$env.STARSHIP_CONFIG = (\$env.XDG_CONFIG_HOME | path join "starship" "starship.toml")

# FZF
\$env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git"
\$env.FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"

# Bat
\$env.BAT_THEME = "Catppuccin Mocha"

# Helix
\$env.HELIX_RUNTIME = "/usr/lib/helix/runtime"

# Go
\$env.GOPATH = (\$env.HOME | path join "go")
\$env.GOROOT = "/usr/lib/go"

# Rust
\$env.RUSTUP_HOME = (\$env.HOME | path join ".rustup")
\$env.CARGO_HOME = (\$env.HOME | path join ".cargo")

# Python
\$env.PYTHONPATH = (\$env.HOME | path join ".local" "lib" "python3" "site-packages")

# Node
\$env.NPM_CONFIG_USERCONFIG = (\$env.XDG_CONFIG_HOME | path join "npm" "npmrc")

# Deno
\$env.DENO_INSTALL_ROOT = (\$env.HOME | path join ".deno")

# Bun
\$env.BUN_INSTALL = (\$env.HOME | path join ".bun")

# Wine
\$env.WINEPREFIX = (\$env.HOME | path join ".wine")

# Steam
\$env.STEAM_EXTRA_COMPAT_TOOLS_PATHS = (\$env.HOME | path join ".steam" "root" "compatibilitytools.d")

# Gamescope
\$env.GAMESCOPE_DISABLE_UPSCALING = "1"
EOF

# ==============================================================================
# 2. STARSHIP CONFIGURATION
# ==============================================================================
echo "Configuring Starship..."

STARSHIP_CONFIG_DIR="$HOME/.config/starship"
mkdir -p "$STARSHIP_CONFIG_DIR"

cat <<EOF > "$STARSHIP_CONFIG_DIR/starship.toml"
# ==============================================================================
# Starship Configuration (Migrated from NixOS)
# ==============================================================================

# General
format = """
[](color_orange)\
\$os\
\$username\
[](bg:color_yellow fg:color_orange)\
\$directory\
[](fg:color_yellow bg:color_aqua)\
\$git_branch\
\$git_status\
[](fg:color_aqua bg:color_blue)\
\$c\
\$rust\
\$golang\
\$nodejs\
\$php\
\$java\
\$kotlin\
\$haskell\
\$python\
\$docker_context\
[](fg:color_blue bg:color_bg3)\
\$time\
[ ](fg:color_bg3)\
\$line_break\$character"""

palette = "catppuccin_mocha"

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
subtext0 = "#a6adc8"
overlay2 = "#9399b2"
overlay1 = "#7f849c"
overlay0 = "#6c7086"
surface2 = "#585b70"
surface1 = "#45475a"
surface0 = "#313244"
base = "#1e1e2e"
mantle = "#181825"
crust = "#11111b"

[os]
disabled = false
style = "bg:color_orange fg:color_fg0"

[os.symbols]
Windows = "󰍲"
Ubuntu = "󰕈"
SUSE = "󰠠"
Raspbian = "󰐿"
Mint = "󰣭"
Macos = "󰀵"
Manjaro = "󱘊"
Linux = "󰌽"
Fedora = "󰣛"
Arch = "󰣇"
Alpine = "󰰰"
Gentoo = "󰣨"
CentOS = "󱄚"
Redhat = "󱄛"
RedHatEnterprise = "󱄛"

[username]
show_always = true
style_user = "bg:color_orange fg:color_fg0"
style_root = "bg:color_orange fg:color_fg0"
format = '[ $user ](\$style)'

[directory]
style = "fg:color_bg1 bg:color_yellow"
format = "[ $path ](\$style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = "󰝚 "
"Pictures" = " "
"Developer" = "󰲋 "

[git_branch]
symbol = ""
style = "bg:color_aqua fg:color_bg0"
format = '[[ $symbol $branch ](fg:color_bg0 bg:color_aqua)](\$style)'

[git_status]
style = "bg:color_aqua fg:color_bg0"
format = '[[($all_status$ahead_behind )](fg:color_bg0 bg:color_aqua)](\$style)'

[c]
symbol = " "
style = "bg:color_blue fg:color_bg0"
format = '[[ $symbol( $version) ](fg:color_bg0 bg:color_blue)](\$style)'

[rust]
symbol = ""
style = "bg:color_blue fg:color_bg0"
format = '[[ $symbol( $version) ](fg:color_bg0 bg:color_blue)](\$style)'

[golang]
symbol = ""
style = "bg:color_blue fg:color_bg0"
format = '[[ $symbol( $version) ](fg:color_bg0 bg:color_blue)](\$style)'

[nodejs]
symbol = ""
style = "bg:color_blue fg:color_bg0"
format = '[[ $symbol( $version) ](fg:color_bg0 bg:color_blue)](\$style)'

[python]
symbol = ""
style = "bg:color_blue fg:color_bg0"
format = '[[ $symbol( $version) ](fg:color_bg0 bg:color_blue)](\$style)'

[docker_context]
symbol = "󰡨"
style = "bg:color_blue fg:color_bg0"
format = '[[ $symbol( $context) ](fg:color_bg0 bg:color_blue)](\$style)'

[time]
disabled = false
time_format = "%R"
style = "bg:color_bg3 fg:color_blue"
format = '[[ ♥ $time ](fg:color_bg1 bg:color_bg3)](\$style)'

[line_break]
disabled = false

[character]
disabled = false
success_symbol = '[❯](bold fg:color_green)'
error_symbol = '[❯](bold fg:color_red)'
vimcmd_symbol = '[❮](bold fg:color_green)'
vimcmd_replace_one_symbol = '[❮](bold fg:color_purple)'
vimcmd_replace_symbol = '[❮](bold fg:color_purple)'
vimcmd_visual_symbol = '[❮](bold fg:color_yellow)'
EOF

# Check if nushell is in /etc/shells
if ! grep -q "/usr/bin/nu" /etc/shells; then
    echo "/usr/bin/nu" | sudo tee -a /etc/shells
fi
