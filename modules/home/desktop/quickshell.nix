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

  warnings = pkgs.writeShellApplication {
    name = "warnings";
    runtimeInputs = [pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.procps];
    text = stripShebang (builtins.readFile (dotfilesDir + "/waybar/scripts/warnings.sh"));
  };

  wifiMonitor = pkgs.writeShellApplication {
    name = "wifi-monitor";
    runtimeInputs = [pkgs.networkmanager];
    text = stripShebang (builtins.readFile (dotfilesDir + "/waybar/scripts/wifi-monitor.sh"));
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

  getPower = pkgs.writeShellApplication {
    name = "get-power-profile";
    runtimeInputs = [pkgs.power-profiles-daemon];
    text = "powerprofilesctl get";
  };

  cyclePower = pkgs.writeShellApplication {
    name = "cycle-power-profile";
    runtimeInputs = [pkgs.power-profiles-daemon];
    text = stripShebang (builtins.readFile (dotfilesDir + "/waybar/scripts/cycle-power-profile.sh"));
  };

  powerMenu = pkgs.writeShellApplication {
    name = "power-menu";
    runtimeInputs = [pkgs.wofi pkgs.systemd pkgs.coreutils];
    text = stripShebang (builtins.readFile (dotfilesDir + "/wofi/scripts/power-menu.sh"));
  };

  audioMenu = pkgs.writeShellApplication {
    name = "audio-menu";
    runtimeInputs = [pkgs.pulseaudio pkgs.wofi pkgs.gawk];
    text = stripShebang (builtins.readFile (dotfilesDir + "/wofi/scripts/audio-switcher.sh"));
  };

  scriptsQml = ''
    import QtQuick

    QtObject {
        readonly property string cpuMem:      "${cpuMem}/bin/cpu-mem"
        readonly property string warnings:    "${warnings}/bin/warnings"
        readonly property string wifiMonitor: "${wifiMonitor}/bin/wifi-monitor"
        readonly property string wifiMenu:    "${wifiMenu}/bin/wifi-menu"
        readonly property string btMenu:      "${btMenu}/bin/bluetooth-menu"
        readonly property string getPower:    "${getPower}/bin/get-power-profile"
        readonly property string cyclePower:  "${cyclePower}/bin/cycle-power-profile"
        readonly property string powerMenu:   "${powerMenu}/bin/power-menu"
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
    cp ${dotfilesDir}/quickshell/NiriIpc.qml     $out/NiriIpc.qml
    cp ${pkgs.writeText "Scripts.qml" scriptsQml} $out/Scripts.qml
  '';
in {
  # quickshell itself + menu scripts that niri key-binds invoke by name
  home.packages = [pkgs.quickshell wifiMenu btMenu powerMenu audioMenu];

  # Single directory link — all QML files (including generated Scripts.qml) live
  # in one store path so QML module resolution finds siblings after symlink resolution.
  xdg.configFile."quickshell".source = shellConfig;

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell status bar";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
      # Cap restarts: max 5 in 60 s to avoid storm-looping on compositor bugs.
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
