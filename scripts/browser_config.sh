#!/bin/bash

echo "=== Configuring Qutebrowser ==="

# Create config directory
CONFIG_DIR="$HOME/.config/qutebrowser"
mkdir -p "$CONFIG_DIR"

echo "Writing $CONFIG_DIR/config.py..."

cat <<EOF > "$CONFIG_DIR/config.py"
# ==============================================================================
# Qutebrowser Configuration (Migrated from NixOS)
# ==============================================================================

# Load settings configured via the GUI (matches loadAutoconfig = true)
config.load_autoconfig(True)

# ==============================================================================
# SETTINGS
# ==============================================================================

# Session
c.auto_save.session = True
c.new_instance_open_target = "window"

# UI & Tabs
c.tabs.background = True
c.tabs.position = "top"  # Default, can be toggled with keybind
c.scrolling.bar = "never"
c.scrolling.smooth = True

# Fonts
# Ensure 'ZedMono Nerd Font Mono' is installed on your system
c.fonts.default_family = "ZedMono Nerd Font Mono"
c.fonts.default_size = "10pt"
c.fonts.web.family.fixed = "ZedMono Nerd Font Mono"

# Colors
c.colors.webpage.darkmode.enabled = True

# Downloads
c.downloads.position = "bottom"
c.downloads.remove_finished = 0

# Completion (The command bar)
c.completion.height = "30%"
c.completion.open_categories = ["history"]
c.completion.scrollbar.padding = 0
c.completion.scrollbar.width = 0
c.completion.show = "always"
c.completion.shrink = True
c.completion.timestamp_format = ""
c.completion.web_history.max_items = 7

# ==============================================================================
# CONTENT & PRIVACY
# ==============================================================================

# Headers
# Note: Keeping the static UA string from your config.
# You might want to remove this to let Qutebrowser use its default modern UA.
c.content.headers.user_agent = "Mozilla/5.0 (X11; Linux x86_64; rv:123.0) Gecko/20100101 Firefox/123.0"
c.content.headers.accept_language = "en-US,en;q=0.5"

# Blocking
c.content.blocking.enabled = True
c.content.blocking.method = "both" # Requires python-adblock package
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://easylist.to/easylist/fanboy-annoyance.txt",
    "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt",
    "https://secure.fanboy.co.nz/fanboy-annoyance.txt",
    "https://easylist-downloads.adblockplus.org/abp-filters-anti-cv.txt",
    "https://pgl.yoyo.org/adservers/serverlist.php?showintro=0;hostformat=hosts",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/legacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2021.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt",
    "https://www.i-dont-care-about-cookies.eu/abp/",
    "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=1&mimetype=plaintext",
    "https://gitlab.com/curben/urlhaus-filter/-/raw/master/urlhaus-filter-online.txt"
]

# Features
c.content.canvas_reading = False
c.content.autoplay = False
c.content.javascript.clipboard = "access"
c.content.pdfjs = True

# ==============================================================================
# SEARCH ENGINES
# ==============================================================================
c.url.searchengines = {
    "DEFAULT": "https://duckduckgo.com/?ia=web&q={}",
    "!d":      "https://duckduckgo.com/?ia=web&q={}",
    "!gc":     "https://github.com/search?q={}&type=code",
    "!g":      "https://www.google.com/search?hl=en&q={}",
    "!gr":     "https://github.com/search?q={}&type=repositories",
    "!gs":     "https://github.com/search?o=desc&q={}&s=stars",
    "!hm":     "https://home-manager-options.extranix.com/?query={}",
    "!nf":     "https://noogle.dev/q?term={}&limit=50&page=1",
    "!np":     "https://search.nixos.org/packages?type=packages&query={}",
    "!npp":    "https://github.com/NixOS/nixpkgs/pulls?q=is%3Apr+is%3Aopen+{}",
    "!nw":     "https://nixos.wiki/index.php?search={}",
    "!yt":     "https://www.youtube.com/results?search_query={}"
}

# ==============================================================================
# KEY BINDINGS
# ==============================================================================

# Open video in MPV
config.bind(';v', 'hint links spawn --detach mpv {hint-url}')

# Toggle UI Elements (Cycle)
# NixOS: config-cycle tabs.show never always ... merged
# Qutebrowser: Chained with ;;
config.bind(',h', 'config-cycle tabs.show never always ;; config-cycle statusbar.show in-mode always ;; config-cycle scrolling.bar never always')

# Toggle Tab Position
config.bind(',s', 'config-cycle tabs.position left top')

EOF

echo "Qutebrowser configuration created."
