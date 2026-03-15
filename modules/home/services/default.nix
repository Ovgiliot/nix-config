# Services home module — management scripts for self-hosted infrastructure.
# Imported by modules/system/services/default.nix via home-manager.users.ethel.imports.
{
  pkgs,
  lib,
  dotfilesDir,
  ...
}: let
  stripShebang = text: lib.strings.removePrefix "#!/usr/bin/env bash\n" text;

  serverStatus = pkgs.writeShellApplication {
    name = "server-status";
    runtimeInputs = with pkgs; [coreutils systemd];
    text = stripShebang (builtins.readFile (dotfilesDir + "/scripts/server-status.sh"));
  };

  trustServerCa = pkgs.writeShellApplication {
    name = "trust-server-ca";
    runtimeInputs = with pkgs; [coreutils];
    text = stripShebang (builtins.readFile (dotfilesDir + "/scripts/trust-server-ca.sh"));
  };
in {
  imports = [
    ../core
  ];

  home.packages = [
    serverStatus
    trustServerCa
  ];
}
