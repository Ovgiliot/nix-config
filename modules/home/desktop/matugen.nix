{
  pkgs,
  lib,
  dotfilesDir,
  ...
}: let
  # Seed files used to bootstrap caches before update-colors has run.
  # Space Cat wallpaper colors (--mode dark --type scheme-content).
  seedGhosttyColors = pkgs.writeText "ghostty-colors-seed.conf" ''
    background = #131315
    foreground = #e5e1e4
    selection-background = #e5e1e4
    selection-foreground = #131315
    cursor-color = #c0c5e4
    cursor-text = #2a2f48
    palette = 0=#474854
    palette = 1=#93000a
    palette = 2=#2e303b
    palette = 3=#42283b
    palette = 4=#2a2f48
    palette = 5=#e3e3f1
    palette = 6=#474854
    palette = 7=#c7c5ce
    palette = 8=#46464d
    palette = 9=#ffb4ab
    palette = 10=#e3e3f1
    palette = 11=#816278
    palette = 12=#c0c5e4
    palette = 13=#e1bcd5
    palette = 14=#c5c5d3
    palette = 15=#e5e1e4
  '';

  seedNiriColors = pkgs.writeText "niri-colors-seed.kdl" ''
    layout {
        focus-ring {
            width 1
            active-color "#c0c5e4"
            inactive-color "#909098"
        }
    }
  '';

  seedQsColors = pkgs.writeText "qs-colors-seed.json" ''
    {
      "pillBg":        "#474854",
      "accent":        "#c0c5e4",
      "barRed":        "#ffb4ab",
      "barAmber":      "#816278",
      "barGreen":      "#656a86",
      "warningBg":     "#816278",
      "criticalBg":    "#ffb4ab",
      "btConnected":   "#c0c5e4",
      "powerPerf":     "#ffb4ab",
      "powerSaver":    "#c5c5d3",
      "powerBalanced": "#c0c5e4",
      "langRu":        "#656a86"
    }
  '';

  seedMakoConfig = pkgs.writeText "mako-config-seed" ''
    font=FiraMono Nerd Font 11
    background-color=#131315cc
    text-color=#e5e1e4
    border-color=#c0c5e4
    border-size=1
    border-radius=8
    padding=8
    default-timeout=6000

    [urgency=high]
    border-color=#ffb4ab
    default-timeout=0
  '';

  seedWofiStyle = pkgs.writeText "wofi-style-seed.css" ''
    window {
        margin: 0px;
        border: 1px solid #46464d;
        background-color: #131315;
        font-family: "FiraMono Nerd Font", "Symbols Nerd Font", sans-serif;
        font-size: 13px;
    }

    #outer-box {
        margin: 5px;
        border: none;
        background-color: transparent;
    }

    #input {
        margin: 5px;
        border: none;
        color: #e5e1e4;
        background-color: #46464d;
    }

    #inner-box {
        margin: 5px;
        border: none;
        background-color: transparent;
    }

    #scroll {
        margin: 0px;
        border: none;
    }

    #text {
        margin: 5px;
        border: none;
        color: #e5e1e4;
    }

    #entry:selected {
        background-color: #46464d;
    }

    #text:selected {
        color: #c0c5e4;
    }
  '';

  seedGtk3Css = pkgs.writeText "gtk3-css-seed.css" ''
    @define-color window_bg_color    #131315;
    @define-color window_fg_color    #e5e1e4;
    @define-color headerbar_bg_color #474854;
    @define-color headerbar_fg_color #c7c5ce;
    @define-color card_bg_color      #2a2f48;
    @define-color accent_bg_color    #c0c5e4;
    @define-color accent_fg_color    #2a2f48;
  '';

  # gtk4.css seed — same color roles as gtk3, targets gtk-4.0/gtk.css.
  seedGtk4Css = pkgs.writeText "gtk4-css-seed.css" ''
    @define-color window_bg_color    #131315;
    @define-color window_fg_color    #e5e1e4;
    @define-color headerbar_bg_color #474854;
    @define-color headerbar_fg_color #c7c5ce;
    @define-color card_bg_color      #2a2f48;
    @define-color accent_bg_color    #c0c5e4;
    @define-color accent_fg_color    #2a2f48;
  '';

  seedSwaylockConfig = pkgs.writeText "swaylock-config-seed" ''
    color=131315
    font=FiraMono Nerd Font
    font-size=16
    indicator-radius=80
    indicator-thickness=8
    line-color=131315
    ring-color=c0c5e4
    inside-color=474854
    key-hl-color=c0c5e4
    separator-color=00000000
    text-color=e5e1e4
    bs-hl-color=ffb4ab
    ring-wrong-color=ffb4ab
    text-wrong-color=ffb4ab
    inside-wrong-color=474854
    line-wrong-color=ffb4ab
    inside-clear-color=474854
    text-clear-color=e5e1e4
    ring-clear-color=c0c5e4
    line-clear-color=131315
    show-failed-attempts=true
  '';

  seedQutebrowserColors = pkgs.writeText "qutebrowser-colors-seed.py" ''
    bg        = "#131315"
    fg        = "#e5e1e4"
    accent    = "#c0c5e4"
    header_bg = "#474854"
    card_bg   = "#2a2f48"
    red       = "#ffb4ab"
    warn      = "#42283b"
    green     = "#2e303b"
    purple    = "#816278"

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
    c.colors.downloads.bar.bg   = bg
    c.colors.downloads.start.fg = fg
    c.colors.downloads.start.bg = accent
    c.colors.downloads.stop.fg  = fg
    c.colors.downloads.stop.bg  = card_bg
    c.colors.downloads.error.fg = red
    c.colors.hints.fg       = bg
    c.colors.hints.bg       = accent
    c.colors.hints.match.fg = fg
    c.colors.keyhint.fg        = fg
    c.colors.keyhint.bg        = header_bg
    c.colors.keyhint.suffix.fg = accent
    c.colors.messages.error.bg      = red
    c.colors.messages.error.border  = red
    c.colors.messages.error.fg      = fg
    c.colors.messages.warning.bg     = warn
    c.colors.messages.warning.border = warn
    c.colors.messages.warning.fg     = bg
    c.colors.messages.info.bg        = header_bg
    c.colors.messages.info.border    = header_bg
    c.colors.messages.info.fg        = fg
    c.colors.prompts.bg          = header_bg
    c.colors.prompts.border      = f"1px solid {accent}"
    c.colors.prompts.fg          = fg
    c.colors.prompts.selected.bg = accent
    c.colors.prompts.selected.fg = fg
    c.colors.statusbar.normal.bg           = bg
    c.colors.statusbar.normal.fg           = fg
    c.colors.statusbar.insert.bg           = accent
    c.colors.statusbar.insert.fg           = fg
    c.colors.statusbar.passthrough.bg      = purple
    c.colors.statusbar.passthrough.fg      = fg
    c.colors.statusbar.private.bg          = card_bg
    c.colors.statusbar.private.fg          = fg
    c.colors.statusbar.command.bg          = header_bg
    c.colors.statusbar.command.fg          = fg
    c.colors.statusbar.command.private.bg  = card_bg
    c.colors.statusbar.command.private.fg  = fg
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
    c.colors.tabs.bar.bg                  = header_bg
    c.colors.tabs.odd.fg                  = fg
    c.colors.tabs.odd.bg                  = header_bg
    c.colors.tabs.even.fg                 = fg
    c.colors.tabs.even.bg                 = bg
    c.colors.tabs.selected.odd.fg         = fg
    c.colors.tabs.selected.odd.bg         = accent
    c.colors.tabs.selected.even.fg        = fg
    c.colors.tabs.selected.even.bg        = accent
    c.colors.tabs.pinned.odd.fg           = fg
    c.colors.tabs.pinned.odd.bg           = header_bg
    c.colors.tabs.pinned.even.fg          = fg
    c.colors.tabs.pinned.even.bg          = bg
    c.colors.tabs.pinned.selected.odd.fg  = fg
    c.colors.tabs.pinned.selected.odd.bg  = accent
    c.colors.tabs.pinned.selected.even.fg = fg
    c.colors.tabs.pinned.selected.even.bg = accent
  '';

  seedNvimHlColors = pkgs.writeText "nvim-hl-colors-seed.lua" ''
    vim.api.nvim_set_hl(0, "Headline1", { bg = "#182030" })
    vim.api.nvim_set_hl(0, "Headline2", { bg = "#182018" })
    vim.api.nvim_set_hl(0, "Headline3", { bg = "#252010" })
    vim.api.nvim_set_hl(0, "Headline4", { bg = "#201818" })
    vim.api.nvim_set_hl(0, "Headline5", { bg = "#182025" })
    vim.api.nvim_set_hl(0, "Headline6", { bg = "#1c1828" })
    vim.api.nvim_set_hl(0, "@org.headline.level1", { fg = "#58a6ff", bold = true })
    vim.api.nvim_set_hl(0, "@org.headline.level2", { fg = "#3fb950", bold = true })
    vim.api.nvim_set_hl(0, "@org.headline.level3", { fg = "#d29922", bold = true })
    vim.api.nvim_set_hl(0, "@org.headline.level4", { fg = "#ff7b72", bold = true })
    vim.api.nvim_set_hl(0, "@org.headline.level5", { fg = "#39c5cf", bold = true })
    vim.api.nvim_set_hl(0, "@org.headline.level6", { fg = "#bc8cff", bold = true })
    vim.api.nvim_set_hl(0, "@org.headline.level7", { fg = "#ffa198", bold = true })
    vim.api.nvim_set_hl(0, "@org.headline.level8", { fg = "#56d364", bold = true })
    vim.api.nvim_set_hl(0, "@org.hyperlink",      { fg = "#2f81f7", underline = true })
    vim.api.nvim_set_hl(0, "@org.hyperlink.desc", { fg = "#2f81f7", underline = true })
    vim.api.nvim_set_hl(0, "@org.hyperlink.url",  { fg = "#79c0ff", underline = true })
  '';
in {
  home.packages = [pkgs.matugen];

  # Link matugen config + templates into XDG config (read-only Nix store).
  xdg.configFile."matugen/config.toml".source = dotfilesDir + "/matugen/config.toml";
  xdg.configFile."matugen/templates".source = dotfilesDir + "/matugen/templates";

  # Bootstrap seed files so niri/ghostty/qs can start before update-colors
  # has ever been run. Activation runs at every switch; guards are idempotent.
  home.activation.matugenSeedColors = lib.hm.dag.entryAfter ["writeBoundary"] ''
    cache="$HOME/.cache/matugen"
    cfg="$HOME/.config"
    $DRY_RUN_CMD mkdir -p "$cache"

    # ghostty-colors.conf — ghostty shows a black terminal without it.
    if [ ! -f "$cache/ghostty-colors.conf" ]; then
      $DRY_RUN_CMD install -m 644 ${seedGhosttyColors} "$cache/ghostty-colors.conf"
    fi

    # niri-colors.kdl — niri fails to start if the include target is missing.
    if [ ! -f "$cache/niri-colors.kdl" ]; then
      $DRY_RUN_CMD install -m 644 ${seedNiriColors} "$cache/niri-colors.kdl"
    fi

    # qs-colors.json — Colors.qml falls back to defaults if missing, but seed anyway.
    if [ ! -f "$cache/qs-colors.json" ]; then
      $DRY_RUN_CMD install -m 644 ${seedQsColors} "$cache/qs-colors.json"
    fi

    # mako/config — no longer managed by HM; seed if not present.
    if [ ! -f "$cfg/mako/config" ]; then
      $DRY_RUN_CMD mkdir -p "$cfg/mako"
      $DRY_RUN_CMD install -m 644 ${seedMakoConfig} "$cfg/mako/config"
    fi

    # wofi/style.css — no longer managed by HM; seed if not present.
    if [ ! -f "$cfg/wofi/style.css" ]; then
      $DRY_RUN_CMD mkdir -p "$cfg/wofi"
      $DRY_RUN_CMD install -m 644 ${seedWofiStyle} "$cfg/wofi/style.css"
    fi

    # gtk-3.0/gtk.css — no longer managed by HM; seed if not present.
    if [ ! -f "$cfg/gtk-3.0/gtk.css" ]; then
      $DRY_RUN_CMD mkdir -p "$cfg/gtk-3.0"
      $DRY_RUN_CMD install -m 644 ${seedGtk3Css} "$cfg/gtk-3.0/gtk.css"
    fi

    # gtk-4.0/gtk.css — no longer managed by HM; seed if not present.
    if [ ! -f "$cfg/gtk-4.0/gtk.css" ]; then
      $DRY_RUN_CMD mkdir -p "$cfg/gtk-4.0"
      $DRY_RUN_CMD install -m 644 ${seedGtk4Css} "$cfg/gtk-4.0/gtk.css"
    fi

    # swaylock/config — no longer managed by HM; seed if not present.
    if [ ! -f "$cfg/swaylock/config" ]; then
      $DRY_RUN_CMD mkdir -p "$cfg/swaylock"
      $DRY_RUN_CMD install -m 644 ${seedSwaylockConfig} "$cfg/swaylock/config"
    fi

    # qutebrowser-colors.py — seed so qutebrowser has colors before first update-colors.
    if [ ! -f "$cache/qutebrowser-colors.py" ]; then
      $DRY_RUN_CMD install -m 644 ${seedQutebrowserColors} "$cache/qutebrowser-colors.py"
    fi

    # nvim-hl-colors.lua — seed so neovim has org headline colors before first update-colors.
    if [ ! -f "$cache/nvim-hl-colors.lua" ]; then
      $DRY_RUN_CMD install -m 644 ${seedNvimHlColors} "$cache/nvim-hl-colors.lua"
    fi
  '';
}
