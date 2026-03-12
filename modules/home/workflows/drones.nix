# Drones workflow — FPV/RC tools.
# Requires desktop (imports it as a dependency).
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
      name = "Betaflight";
      url = "https://app.betaflight.com";
      icon = "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse1.mm.bing.net%2Fth%2Fid%2FOIP.wrdMW93WN-mqGwFE1yu8BQAAAA%3Fpid%3DApi&f=1&ipt=4c96b08ab4306ba377bd47d8d4e1c647a6e6667bfcf592b20c7f6096538e277a";
    }
  ];
in {
  home.file = builtins.listToAttrs (map mkDesktopFile webApps);

  # TODO: qgroundcontrol (check nixpkgs availability)
}
