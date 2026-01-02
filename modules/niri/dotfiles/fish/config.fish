# ==============================================================================
# SPIDY FISH CONFIG
# ==============================================================================

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
# Set cursor theme for niri compositor
set -gx XCURSOR_THEME "Bibata-Modern-Ice"
set -gx XCURSOR_SIZE "24"

# Add scripts directory to PATH
fish_add_path $HOME/.config/scripts