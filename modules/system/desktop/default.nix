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
  # Force X11 backend: GTK3's Wayland popup implementation causes menu
  # flickering on Niri. Routing through xwayland-satellite avoids this.
  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "gparted";
      paths = [pkgs.gparted];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/gparted --set GDK_BACKEND x11
      '';
    })
  ];

  home-manager.users.ethel.imports = [
    ../../home/desktop
  ];
}
