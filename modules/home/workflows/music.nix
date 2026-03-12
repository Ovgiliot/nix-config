# Music production home workflow — notation, DAW, audio routing.
{
  config,
  pkgs,
  lib,
  ...
}: let
  homeLib = import ../lib.nix {inherit lib pkgs config;};
  inherit (homeLib) mkDesktopFile;

  webApps = [
    {
      name = "Apple Music";
      url = "https://music.apple.com";
      icon = "audio-x-generic";
    }
  ];
in {
  home.packages = with pkgs; [
    musescore
    # helvum removed from nixpkgs (unmaintained, vulnerable dep).
    # TODO: evaluate crosspipe as replacement PipeWire patchbay.
    # TODO: carla, reaper (scaffold — check nixpkgs availability)
  ];

  home.file = builtins.listToAttrs (map mkDesktopFile webApps);
}
