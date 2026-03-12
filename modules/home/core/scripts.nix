# Core scripts — system maintenance, available on all machines (including servers).
{
  pkgs,
  lib,
  dotfilesDir,
  ...
}: let
  stripShebang = text: lib.strings.removePrefix "#!/usr/bin/env bash\n" text;

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
