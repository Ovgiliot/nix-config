{
  pkgs,
  lib,
  dotfilesDir,
  ...
}: let
  stripShebang = text: lib.strings.removePrefix "#!/usr/bin/env bash\n" text;

  cpuMem = pkgs.writeShellApplication {
    name = "cpu-mem";
    runtimeInputs = [pkgs.coreutils pkgs.gawk pkgs.gnugrep];
    text = stripShebang (builtins.readFile (dotfilesDir + "/waybar/scripts/cpu-mem.sh"));
  };

  infoBox = pkgs.writeShellApplication {
    name = "info-box";
    runtimeInputs = [pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.procps pkgs.playerctl];
    text = stripShebang (builtins.readFile (dotfilesDir + "/waybar/scripts/info-box.sh"));
  };

  language = pkgs.writeShellApplication {
    name = "language";
    runtimeInputs = [pkgs.niri-unstable pkgs.jq];
    text = stripShebang (builtins.readFile (dotfilesDir + "/waybar/scripts/language.sh"));
  };

  status = pkgs.writeShellApplication {
    name = "status";
    runtimeInputs = [pkgs.networkmanager pkgs.bluez pkgs.power-profiles-daemon pkgs.coreutils];
    text = stripShebang (builtins.readFile (dotfilesDir + "/waybar/scripts/status.sh"));
  };

  cyclePower = pkgs.writeShellApplication {
    name = "cycle-power-profile";
    runtimeInputs = [pkgs.power-profiles-daemon];
    text = stripShebang (builtins.readFile (dotfilesDir + "/waybar/scripts/cycle-power-profile.sh"));
  };

  wifiMenu = pkgs.writeShellApplication {
    name = "wifi-menu";
    runtimeInputs = [pkgs.networkmanager pkgs.wofi pkgs.gawk pkgs.gnused pkgs.gnugrep];
    text = stripShebang (builtins.readFile (dotfilesDir + "/wofi/scripts/wifi-menu.sh"));
  };

  btMenu = pkgs.writeShellApplication {
    name = "bluetooth-menu";
    runtimeInputs = [pkgs.bluez pkgs.wofi pkgs.libnotify pkgs.coreutils pkgs.gnugrep pkgs.gnused];
    text = stripShebang (builtins.readFile (dotfilesDir + "/wofi/scripts/bluetooth-menu.sh"));
  };

  scriptsQml = ''
    import QtQuick

    QtObject {
        readonly property string cpuMem:     "${cpuMem}/bin/cpu-mem"
        readonly property string infoBox:    "${infoBox}/bin/info-box"
        readonly property string language:   "${language}/bin/language"
        readonly property string status:     "${status}/bin/status"
        readonly property string cyclePower: "${cyclePower}/bin/cycle-power-profile"
        readonly property string wifiMenu:   "${wifiMenu}/bin/wifi-menu"
        readonly property string btMenu:     "${btMenu}/bin/bluetooth-menu"
    }
  '';
in {
  home.packages = [pkgs.quickshell];

  # Link each QML file individually so Scripts.qml (generated) can live alongside them
  xdg.configFile."quickshell/shell.qml".source = dotfilesDir + "/quickshell/shell.qml";
  xdg.configFile."quickshell/Clock.qml".source = dotfilesDir + "/quickshell/Clock.qml";
  xdg.configFile."quickshell/Workspaces.qml".source = dotfilesDir + "/quickshell/Workspaces.qml";
  xdg.configFile."quickshell/CpuMem.qml".source = dotfilesDir + "/quickshell/CpuMem.qml";
  xdg.configFile."quickshell/InfoBox.qml".source = dotfilesDir + "/quickshell/InfoBox.qml";
  xdg.configFile."quickshell/Language.qml".source = dotfilesDir + "/quickshell/Language.qml";
  xdg.configFile."quickshell/StatusIcons.qml".source = dotfilesDir + "/quickshell/StatusIcons.qml";

  # Scripts.qml: generated QtObject exposing Nix store paths for each shell script
  xdg.configFile."quickshell/Scripts.qml".text = scriptsQml;

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell status bar";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
      RestartSec = "2";
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
