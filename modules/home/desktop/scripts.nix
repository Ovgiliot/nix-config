{
  pkgs,
  lib,
  config,
  dotfilesDir,
  ...
}: let
  homeLib = import ../lib.nix {inherit lib pkgs config;};
  inherit (homeLib) stripShebang;

  # ── Menu Scripts ─────────────────────────────────────────────────────────
  # Idle scripts live in compositor modules (niri-idle, hypridle, etc.).

  wifiMenu = pkgs.writeShellApplication {
    name = "wifi-menu";
    runtimeInputs = with pkgs; [networkmanager wofi gawk gnused gnugrep];
    text = stripShebang (builtins.readFile (dotfilesDir + "/wofi/scripts/wifi-menu.sh"));
  };

  btMenu = pkgs.writeShellApplication {
    name = "bluetooth-menu";
    runtimeInputs = with pkgs; [bluez wofi libnotify coreutils gnugrep gnused util-linux];
    text = stripShebang (builtins.readFile (dotfilesDir + "/wofi/scripts/bluetooth-menu.sh"));
  };

  powerMenu = pkgs.writeShellApplication {
    name = "power-menu";
    runtimeInputs = with pkgs; [wofi systemd coreutils];
    text = stripShebang (builtins.readFile (dotfilesDir + "/wofi/scripts/power-menu.sh"));
  };

  audioMenu = pkgs.writeShellApplication {
    name = "audio-menu";
    runtimeInputs = with pkgs; [pulseaudio wofi gawk];
    text = stripShebang (builtins.readFile (dotfilesDir + "/wofi/scripts/audio-switcher.sh"));
  };
in {
  home.packages = [
    wifiMenu
    btMenu
    powerMenu
    audioMenu
  ];
}
