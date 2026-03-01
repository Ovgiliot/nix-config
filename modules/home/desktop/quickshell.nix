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
    runtimeInputs = [pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.jq pkgs.procps pkgs.playerctl];
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

  powerMenu = pkgs.writeShellApplication {
    name = "power-menu";
    runtimeInputs = [pkgs.wofi pkgs.systemd pkgs.coreutils];
    text = stripShebang (builtins.readFile (dotfilesDir + "/wofi/scripts/power-menu.sh"));
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
        readonly property string powerMenu:  "${powerMenu}/bin/power-menu"
    }
  '';

  # Bundle all QML files into one derivation so QML module resolution finds
  # sibling types correctly. Per-file symlinks each resolve to an isolated
  # store path, causing "X is not a type" crashes at runtime.
  shellConfig = pkgs.runCommand "quickshell-config" {} ''
    mkdir $out
    cp ${dotfilesDir}/quickshell/shell.qml       $out/shell.qml
    cp ${dotfilesDir}/quickshell/Clock.qml       $out/Clock.qml
    cp ${dotfilesDir}/quickshell/Workspaces.qml  $out/Workspaces.qml
    cp ${dotfilesDir}/quickshell/CpuMem.qml      $out/CpuMem.qml
    cp ${dotfilesDir}/quickshell/InfoBox.qml     $out/InfoBox.qml
    cp ${dotfilesDir}/quickshell/Language.qml    $out/Language.qml
    cp ${dotfilesDir}/quickshell/StatusIcons.qml $out/StatusIcons.qml
    cp ${pkgs.writeText "Scripts.qml" scriptsQml} $out/Scripts.qml
  '';
in {
  # quickshell itself + menu scripts that niri key-binds invoke by name
  home.packages = [pkgs.quickshell wifiMenu btMenu powerMenu];

  # Single directory link — all QML files (including generated Scripts.qml) live
  # in one store path so QML module resolution finds siblings after symlink resolution.
  xdg.configFile."quickshell".source = shellConfig;

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell status bar";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
