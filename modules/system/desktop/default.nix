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
  # GTK3 popup menus break on Niri (tiling compositor) and xwayland-satellite
  # alike. The Niri wiki recommends running such apps inside a nested stacking
  # compositor. Cage (kiosk compositor) gives GParted a proper stacking env
  # where popup menus work correctly, shown as a single window in Niri.
  environment.systemPackages = let
    gparted-wrapped = pkgs.symlinkJoin {
      name = "gparted";
      paths = [pkgs.gparted];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/gparted --prefix PATH : ${pkgs.cage}/bin \
          --run 'if [ -z "$INSIDE_CAGE" ]; then exec env INSIDE_CAGE=1 cage -- "$0" "$@"; fi'

        # .desktop files are symlinks into the store — replace with
        # mutable copies so we can patch the Exec path to use our wrapper.
        for f in $out/share/applications/*.desktop; do
          cp --remove-destination "$(readlink -f "$f")" "$f"
          substituteInPlace "$f" \
            --replace-fail "${pkgs.gparted}" "$out"
        done
      '';
    };
  in [
    gparted-wrapped
  ];

  home-manager.users.ethel.imports = [
    ../../home/desktop
  ];
}
