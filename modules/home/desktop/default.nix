{...}: let
  # --- Shared colour palette ---
  # Single source of truth for all desktop theming.
  # Consumed by theme.nix (GTK / swaylock) and qutebrowser.nix (generated config).
  palette = {
    bg = "#131314";
    fg = "#e6edf3";
    accent = "#2f81f7";
    accent_fg = "#ffffff";
    header_bg = "#1a1a1b";
    card_bg = "#1d1d1e";
  };
in {
  _module.args.palette = palette;

  imports = [
    ./theme.nix
    ./niri.nix
    ./scripts.nix
    ./quickshell.nix
    ./ghostty.nix
    ./notifications.nix
    ./launcher.nix
    ./matugen.nix
    ./apps.nix
    ./qutebrowser.nix
  ];
}
