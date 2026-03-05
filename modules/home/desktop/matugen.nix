{
  pkgs,
  lib,
  dotfilesDir,
  ...
}: let
  # Minimal placeholder installed only when no wallpaper has been set yet.
  # niri crashes if its include target is absent; all other apps handle a
  # missing file gracefully. Colors are neutral black — not a theme choice.
  niriPlaceholder = pkgs.writeText "niri-colors-placeholder.kdl" ''
    layout {
        focus-ring {
            width 1
            active-color "#000000"
            inactive-color "#000000"
        }
        shadow {
            color "#00000007"
        }
    }
  '';
in {
  home.packages = [pkgs.matugen];

  # Link matugen config + templates into XDG config (read-only Nix store).
  xdg.configFile."matugen/config.toml".source = dotfilesDir + "/matugen/config.toml";
  xdg.configFile."matugen/templates".source = dotfilesDir + "/matugen/templates";

  # Regenerate all color files from the current wallpaper on every switch so
  # template changes take effect immediately without a manual update-colors call.
  # Per-template post_hooks (ghostty, mako, niri reload) run automatically.
  # If no wallpaper has been set yet, write a neutral structural stub for niri
  # — the only app that crashes when its include target is missing.
  home.activation.matugenColors = lib.hm.dag.entryAfter ["writeBoundary"] ''
    cache="$HOME/.cache/matugen"
    $DRY_RUN_CMD mkdir -p "$cache"

    WALLPAPER="$HOME/.config/wallpaper.jpg"
    if [ -f "$WALLPAPER" ]; then
      $DRY_RUN_CMD ${pkgs.matugen}/bin/matugen image "$WALLPAPER" \
        --mode dark --type scheme-content
    fi

    # niri crashes if its include target is absent. Install the placeholder
    # only when matugen did not produce the file (wallpaper not set yet).
    if [ ! -f "$cache/niri-colors.kdl" ]; then
      $DRY_RUN_CMD install -m 644 ${niriPlaceholder} "$cache/niri-colors.kdl"
    fi
  '';
}
