{
  pkgs,
  lib,
  dotfilesDir,
  ...
}: {
  home.packages = [pkgs.matugen];

  # Link matugen config + templates into XDG config (read-only Nix store).
  xdg.configFile."matugen/config.toml".source = dotfilesDir + "/matugen/config.toml";
  xdg.configFile."matugen/templates".source = dotfilesDir + "/matugen/templates";

  # Regenerate all color files from the current wallpaper on every switch so
  # template changes take effect immediately without a manual update-colors call.
  # Per-template post_hooks (ghostty, mako, niri reload) run automatically.
  # Compositor-specific placeholder workarounds (e.g. niri crashes without its
  # include target) live in the compositor's home module.
  home.activation.matugenColors = lib.hm.dag.entryAfter ["writeBoundary"] ''
    WALLPAPER="$HOME/.config/wallpaper.jpg"
    if [ -f "$WALLPAPER" ]; then
      $DRY_RUN_CMD ${pkgs.matugen}/bin/matugen image "$WALLPAPER" \
        --mode dark --type scheme-fidelity -r gaussian --source-color-index 0
    fi
  '';
}
