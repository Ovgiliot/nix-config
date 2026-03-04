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
    focus-ring {
        width 1
        active-color "#c0c5e4"
        inactive-color "#909098"
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
      $DRY_RUN_CMD cp ${seedGhosttyColors} "$cache/ghostty-colors.conf"
    fi

    # niri-colors.kdl — niri fails to start if the include target is missing.
    if [ ! -f "$cache/niri-colors.kdl" ]; then
      $DRY_RUN_CMD cp ${seedNiriColors} "$cache/niri-colors.kdl"
    fi

    # qs-colors.json — Colors.qml falls back to defaults if missing, but seed anyway.
    if [ ! -f "$cache/qs-colors.json" ]; then
      $DRY_RUN_CMD cp ${seedQsColors} "$cache/qs-colors.json"
    fi

    # mako/config — no longer managed by HM; seed if not present.
    if [ ! -f "$cfg/mako/config" ]; then
      $DRY_RUN_CMD mkdir -p "$cfg/mako"
      $DRY_RUN_CMD cp ${seedMakoConfig} "$cfg/mako/config"
    fi

    # wofi/style.css — no longer managed by HM; seed if not present.
    if [ ! -f "$cfg/wofi/style.css" ]; then
      $DRY_RUN_CMD mkdir -p "$cfg/wofi"
      $DRY_RUN_CMD cp ${seedWofiStyle} "$cfg/wofi/style.css"
    fi
  '';
}
