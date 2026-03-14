# Niri home module — XDG config, niri-specific packages, idle script.
# Extracted from the shared desktop layer so compositors are composable.
{
  pkgs,
  lib,
  config,
  dotfilesDir,
  ...
}: let
  homeLib = import ../../lib.nix {inherit lib pkgs config;};
  inherit (homeLib) stripShebang;

  # ── Idle / Session Management ─────────────────────────────────────────────
  # Extracted from the niri config.kdl spawn-sh-at-startup one-liner so the
  # idle policy is readable, diffable, and has declared runtime dependencies.
  niriIdle = pkgs.writeShellApplication {
    name = "niri-idle";
    runtimeInputs = with pkgs; [swayidle brightnessctl];
    text = ''
      exec swayidle -w \
        timeout 300  'brightnessctl -s set 10%' \
        resume       'brightnessctl -r' \
        timeout 600  'swaylock -f' \
        timeout 900  'niri msg action power-off-monitors' \
        timeout 1800 'systemctl hibernate' \
        before-sleep 'swaylock -f'
    '';
  };

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
  # Niri raw dotfiles (config.kdl + includes).
  xdg.configFile."niri".source = dotfilesDir + "/niri";

  home.packages = [
    pkgs.xwayland-satellite # X11 app support in Niri
    pkgs.swayidle
    pkgs.swaylock-effects # Drop-in replacement with wp-fractional-scale-v1 support
    niriIdle
  ];

  # niri crashes if its include target is absent. Install the placeholder
  # only when matugen did not produce the file (wallpaper not set yet).
  home.activation.niriPlaceholder = lib.hm.dag.entryAfter ["writeBoundary"] ''
    cache="$HOME/.cache/matugen"
    $DRY_RUN_CMD mkdir -p "$cache"
    if [ ! -f "$cache/niri-colors.kdl" ]; then
      $DRY_RUN_CMD install -m 644 ${niriPlaceholder} "$cache/niri-colors.kdl"
    fi
  '';
}
