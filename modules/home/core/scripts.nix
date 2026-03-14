# Core scripts — system maintenance, available on all machines (including servers).
{
  pkgs,
  lib,
  config,
  dotfilesDir,
  ...
}: let
  homeLib = import ../lib.nix {inherit lib pkgs config;};
  inherit (homeLib) stripShebang;

  nixosRebuild = pkgs.writeShellApplication {
    name = "nixos-rebuild-dotfiles";
    runtimeInputs = [pkgs.git];
    text = stripShebang (builtins.readFile (dotfilesDir + "/scripts/nixos-rebuild-with-git.sh"));
  };

  updateNixos = pkgs.writeShellApplication {
    name = "update-nixos";
    runtimeInputs = [pkgs.git];
    text = stripShebang (builtins.readFile (dotfilesDir + "/scripts/update.sh"));
  };
in {
  home.packages = [
    nixosRebuild
    updateNixos
  ];
}
