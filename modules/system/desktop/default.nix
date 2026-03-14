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
  ];

  # Disk partition editor — system-level since it requires root for disk ops.
  environment.systemPackages = [pkgs.gparted];

  home-manager.users.ethel.imports = [
    ../../home/desktop
  ];
}
