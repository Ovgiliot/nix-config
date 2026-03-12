# Desktop home — Wayland compositor, status bar, theming, apps.
# Imports core as a dependency (HM deduplicates).
{...}: {
  imports = [
    ../core
    ./ranger.nix
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
