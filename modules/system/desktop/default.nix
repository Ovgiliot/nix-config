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
  # Uses symlinkJoin + postBuild to wrap the binary AND patch .desktop files
  # so the wrapper is used regardless of how GParted is launched.
  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "gparted";
      paths = [pkgs.gparted];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/gparted --set GDK_BACKEND x11

        # .desktop files are symlinks into the store — replace with
        # mutable copies so we can patch the Exec path to use our wrapper.
        for f in $out/share/applications/*.desktop; do
          cp --remove-destination "$(readlink -f "$f")" "$f"
          substituteInPlace "$f" \
            --replace-fail "${pkgs.gparted}" "$out"
        done
      '';
    })
  ];

  home-manager.users.ethel.imports = [
    ../../home/desktop
  ];
}
