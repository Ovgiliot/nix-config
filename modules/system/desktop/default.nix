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
    pkgs.xdg-user-dirs # XDG directory resolver — needed by Flutter path_provider and other apps.

    # GTK3 dialog tool (zenity-compatible). Apps like Flutter's file_picker probe
    # for `zenity` on PATH. Nixpkgs' zenity 4.x is GTK4/libadwaita which renders
    # invisibly under some Wayland compositors; yad is GTK3 and works reliably.
    # The symlink exposes it as `zenity` so apps that probe by name find it.
    (pkgs.symlinkJoin {
      name = "yad-as-zenity";
      paths = [pkgs.yad];
      postBuild = ''
        ln -s ${pkgs.yad}/bin/yad $out/bin/zenity
      '';
    })
  ];

  home-manager.users.ethel.imports = [
    ../../home/desktop
  ];
}
