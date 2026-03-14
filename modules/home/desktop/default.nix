# Desktop home — Wayland compositor, status bar, theming, wallpaper, apps.
# Imports core as a dependency (HM deduplicates).
{...}: {
  imports = [
    ../core
    ./ranger.nix
    ./theme.nix
    ./scripts.nix
    ./quickshell.nix
    ./ghostty.nix
    ./notifications.nix
    ./launcher.nix
    ./matugen.nix
    ./wallpaper.nix
    ./apps.nix
    ./storage.nix
  ];
}
