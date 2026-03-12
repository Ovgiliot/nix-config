# Desktop infrastructure — Wayland compositor, audio, input.
# Imports core as a dependency (NixOS module system deduplicates).
{inputs, ...}: {
  imports = [
    inputs.niri.nixosModules.niri
    ../core
    ./audio.nix
    ./display.nix
    ./input.nix
  ];

  home-manager.users.ethel.imports = [
    ../../home/desktop
  ];
}
