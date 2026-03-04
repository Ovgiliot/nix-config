# ~/.config/qutebrowser/config.py
# Opinionated qutebrowser config — colors match modules/home/desktop/theme.nix.
# Do not use the in-browser :set / autoconfig.yml mechanism; all settings live here.
config.load_autoconfig(False)

# --- Behavior ---
c.auto_save.session = False
c.downloads.location.directory = "~/Downloads"
c.downloads.location.prompt = False
c.editor.command = ["ghostty", "-e", "nvim", "{file}"]
c.spellcheck.languages = ["en-US"]
c.tabs.last_close = "close"
c.url.default_page = "about:blank"
c.url.start_pages = "about:blank"

# Search engines — DEFAULT is DuckDuckGo; prefix shortcuts for everything else.
c.url.searchengines = {
    "DEFAULT": "https://duckduckgo.com/?q={}",
    "g": "https://www.google.com/search?q={}",
    "gh": "https://github.com/search?q={}",
    "nix": "https://search.nixos.org/packages?query={}",
    "yt": "https://www.youtube.com/results?search_query={}",
    "w": "https://en.wikipedia.org/wiki/{}",
}

# --- Privacy ---
c.content.cookies.accept = "no-3rdparty"
c.content.geolocation = False
c.content.notifications.enabled = False

# --- Appearance ---
c.fonts.default_family = "FiraMono Nerd Font"
c.fonts.default_size = "11pt"
c.fonts.monospace = "FiraMono Nerd Font"

# Dark mode for web pages — force pages to use a dark palette where supported.
c.colors.webpage.preferred_color_scheme = "dark"
c.colors.webpage.darkmode.enabled = True

# System palette (matches theme.nix exactly).
bg        = "#131314"
fg        = "#e6edf3"
accent    = "#2f81f7"
header_bg = "#1a1a1b"
card_bg   = "#1d1d1e"
red       = "#ff3333"
warn      = "#f0a500"
green     = "#3fb950"
purple    = "#9a348e"

# Completion
c.colors.completion.fg                          = fg
c.colors.completion.odd.bg                      = bg
c.colors.completion.even.bg                     = card_bg
c.colors.completion.category.fg                 = accent
c.colors.completion.category.bg                 = header_bg
c.colors.completion.category.border.top         = header_bg
c.colors.completion.category.border.bottom      = header_bg
c.colors.completion.item.selected.fg            = fg
c.colors.completion.item.selected.bg            = accent
c.colors.completion.item.selected.border.top    = accent
c.colors.completion.item.selected.border.bottom = accent
c.colors.completion.match.fg                    = accent
c.colors.completion.scrollbar.fg                = fg
c.colors.completion.scrollbar.bg                = header_bg

# Downloads bar
c.colors.downloads.bar.bg    = bg
c.colors.downloads.start.fg  = fg
c.colors.downloads.start.bg  = accent
c.colors.downloads.stop.fg   = fg
c.colors.downloads.stop.bg   = card_bg
c.colors.downloads.error.fg  = red

# Hints (link-follow overlay)
c.colors.hints.fg       = bg
c.colors.hints.bg       = accent
c.colors.hints.match.fg = fg

# Key hint overlay
c.colors.keyhint.fg        = fg
c.colors.keyhint.bg        = header_bg
c.colors.keyhint.suffix.fg = accent

# Messages
c.colors.messages.error.bg      = red
c.colors.messages.error.border  = red
c.colors.messages.error.fg      = fg
c.colors.messages.warning.bg     = warn
c.colors.messages.warning.border = warn
c.colors.messages.warning.fg     = bg
c.colors.messages.info.bg        = header_bg
c.colors.messages.info.border    = header_bg
c.colors.messages.info.fg        = fg

# Prompts
c.colors.prompts.bg          = header_bg
c.colors.prompts.border      = f"1px solid {accent}"
c.colors.prompts.fg          = fg
c.colors.prompts.selected.bg = accent
c.colors.prompts.selected.fg = fg

# Status bar
c.colors.statusbar.normal.bg        = bg
c.colors.statusbar.normal.fg        = fg
c.colors.statusbar.insert.bg        = accent
c.colors.statusbar.insert.fg        = fg
c.colors.statusbar.passthrough.bg   = purple
c.colors.statusbar.passthrough.fg   = fg
c.colors.statusbar.private.bg       = card_bg
c.colors.statusbar.private.fg       = fg
c.colors.statusbar.command.bg       = header_bg
c.colors.statusbar.command.fg       = fg
c.colors.statusbar.command.private.bg = card_bg
c.colors.statusbar.command.private.fg = fg
c.colors.statusbar.caret.bg            = purple
c.colors.statusbar.caret.fg            = fg
c.colors.statusbar.caret.selection.bg  = purple
c.colors.statusbar.caret.selection.fg  = fg
c.colors.statusbar.progress.bg         = accent
c.colors.statusbar.url.fg              = fg
c.colors.statusbar.url.error.fg        = red
c.colors.statusbar.url.hover.fg        = accent
c.colors.statusbar.url.success.http.fg  = warn
c.colors.statusbar.url.success.https.fg = green
c.colors.statusbar.url.warn.fg          = warn

# Tabs
c.colors.tabs.bar.bg                = header_bg
c.colors.tabs.odd.fg                = fg
c.colors.tabs.odd.bg                = header_bg
c.colors.tabs.even.fg               = fg
c.colors.tabs.even.bg               = bg
c.colors.tabs.selected.odd.fg       = fg
c.colors.tabs.selected.odd.bg       = accent
c.colors.tabs.selected.even.fg      = fg
c.colors.tabs.selected.even.bg      = accent
c.colors.tabs.pinned.odd.fg         = fg
c.colors.tabs.pinned.odd.bg         = header_bg
c.colors.tabs.pinned.even.fg        = fg
c.colors.tabs.pinned.even.bg        = bg
c.colors.tabs.pinned.selected.odd.fg  = fg
c.colors.tabs.pinned.selected.odd.bg  = accent
c.colors.tabs.pinned.selected.even.fg = fg
c.colors.tabs.pinned.selected.even.bg = accent

# --- Keybinds ---
# Edit current URL in $EDITOR
config.bind(",e", "edit-url")
# Open hinted link in a new tab
config.bind(";t", "hint links tab")
# Toggle dark mode for the current page
config.bind(",d", "config-cycle colors.webpage.darkmode.enabled True False")
