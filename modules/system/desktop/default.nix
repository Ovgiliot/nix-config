# Desktop infrastructure — Wayland compositor, audio, input.
# Imports core as a dependency (NixOS module system deduplicates).
{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.niri.nixosModules.niri
    ../core
    ./audio.nix
    ./display.nix
    ./input.nix
    ./storage.nix
  ];

  environment.systemPackages = [
    pkgs.gparted # Disk partition editor — system-level since it requires root for disk ops.
    pkgs.zenity # GTK dialog tool — used by Flutter and other apps for native file pickers.
  ];

  home-manager.users.ethel.imports = [
    ../../home/desktop
  ];
}
