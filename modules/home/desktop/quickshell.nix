{
  pkgs,
  lib,
  dotfilesDir,
  ...
}: let
  stripShebang = text: lib.strings.removePrefix "#!/usr/bin/env bash\n" text;

  wifiMonitor = pkgs.writeShellApplication {
    name = "wifi-monitor";
    runtimeInputs = [pkgs.networkmanager];
    text = stripShebang (builtins.readFile (dotfilesDir + "/quickshell/scripts/wifi-monitor.sh"));
  };

  status = pkgs.writeShellApplication {
    name = "status";
    runtimeInputs = [pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.procps];
    text = stripShebang (builtins.readFile (dotfilesDir + "/quickshell/scripts/system-stats.sh"));
  };

  getPower = pkgs.writeShellApplication {
    name = "get-power-profile";
    runtimeInputs = [pkgs.power-profiles-daemon];
    text = "powerprofilesctl get";
  };

  # ---------------------------------------------------------------------------
  # Wallpaper management
  # set-wallpaper is defined here (not in laptop/wallpaper.nix) so its Nix
  # store path can be injected into Scripts.qml for use by WallpaperPicker.qml.
  # swww img is guarded with || true so it is a graceful no-op on workstation
  # where swww-daemon is not running.
  # update-colors is called via ~/.nix-profile/bin — a stable path for any
  # home-manager user — because Scripts.qml only knows store paths, not PATH.
  # ---------------------------------------------------------------------------

  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper";
    runtimeInputs = with pkgs; [swww coreutils];
    text = ''
      if [ -z "''${1-}" ]; then
        echo "Usage: set-wallpaper <path>" >&2
        exit 1
      fi
      SRC=$(realpath "$1")
      if [ ! -f "$SRC" ]; then
        echo "set-wallpaper: not found: $SRC" >&2
        exit 1
      fi
      # Stable copy for matugen colour extraction.
      cp "$SRC" "$HOME/.config/wallpaper.jpg"
      # Record source path so WallpaperPicker can pre-select on next open.
      printf '%s' "$SRC" > "$HOME/.cache/qs-current-wallpaper"
      # Apply via swww (no-op on workstation where swww-daemon is not running).
      swww img "$SRC" --transition-type random || true
      # Regenerate colour scheme to match the new wallpaper.
      "$HOME/.nix-profile/bin/update-colors"
    '';
  };

  listWallpapers = pkgs.writeShellApplication {
    name = "list-wallpapers";
    runtimeInputs = with pkgs; [findutils coreutils];
    text = ''
      DIR="$HOME/Pictures/Wallpapers"
      [ -d "$DIR" ] || exit 0
      find "$DIR" -maxdepth 1 -type f \( \
        -name "*.jpg" -o -name "*.jpeg" -o \
        -name "*.png" -o \
        -name "*.gif" -o \
        -name "*.webp" \) | sort
    '';
  };

  # Toggles visibility flag file read by WallpaperPicker's FileView.
  toggleWallpaperPicker = pkgs.writeShellApplication {
    name = "toggle-wallpaper-picker";
    runtimeInputs = with pkgs; [gnugrep];
    text = ''
      FLAG="$HOME/.cache/qs-wallpaper-open"
      if [ -f "$FLAG" ] && grep -q '"show":true' "$FLAG" 2>/dev/null; then
        printf '{"show":false}' > "$FLAG"
      else
        printf '{"show":true}' > "$FLAG"
      fi
    '';
  };

  hideWallpaperPicker = pkgs.writeShellApplication {
    name = "hide-wallpaper-picker";
    runtimeInputs = [];
    text = ''printf '{"show":false}' > "$HOME/.cache/qs-wallpaper-open"'';
  };

  scriptsQml = ''
    import QtQuick

    QtObject {
        readonly property string wifiMonitor:           "${wifiMonitor}/bin/wifi-monitor"
        readonly property string status:                "${status}/bin/status"
        readonly property string getPower:              "${getPower}/bin/get-power-profile"
        readonly property string setWallpaper:          "${setWallpaper}/bin/set-wallpaper"
        readonly property string listWallpapers:        "${listWallpapers}/bin/list-wallpapers"
        readonly property string toggleWallpaperPicker: "${toggleWallpaperPicker}/bin/toggle-wallpaper-picker"
        readonly property string hideWallpaperPicker:   "${hideWallpaperPicker}/bin/hide-wallpaper-picker"
    }
  '';

  # Bundle all QML files into one derivation so QML module resolution finds
  # sibling types correctly. Per-file symlinks each resolve to an isolated
  # store path, causing "X is not a type" crashes at runtime.
  shellConfig = pkgs.runCommand "quickshell-config" {} ''
    mkdir $out
    cp ${dotfilesDir}/quickshell/shell.qml              $out/shell.qml
    cp ${dotfilesDir}/quickshell/Clock.qml              $out/Clock.qml
    cp ${dotfilesDir}/quickshell/Workspaces.qml         $out/Workspaces.qml
    cp ${dotfilesDir}/quickshell/CpuMem.qml             $out/CpuMem.qml
    cp ${dotfilesDir}/quickshell/InfoBox.qml            $out/InfoBox.qml
    cp ${dotfilesDir}/quickshell/Language.qml           $out/Language.qml
    cp ${dotfilesDir}/quickshell/StatusIcons.qml        $out/StatusIcons.qml
    cp ${dotfilesDir}/quickshell/NiriIpc.qml            $out/NiriIpc.qml
    cp ${dotfilesDir}/quickshell/StatusPoller.qml       $out/StatusPoller.qml
    cp ${dotfilesDir}/quickshell/Colors.qml             $out/Colors.qml
    cp ${dotfilesDir}/quickshell/WallpaperPicker.qml    $out/WallpaperPicker.qml
    cp ${pkgs.writeText "Scripts.qml" scriptsQml}       $out/Scripts.qml
  '';
in {
  # quickshell itself + wallpaper management scripts (available on all desktops;
  # swww img call in set-wallpaper is a graceful no-op when swww-daemon is absent).
  home.packages = [
    pkgs.quickshell
    setWallpaper
    listWallpapers
    toggleWallpaperPicker
    hideWallpaperPicker
  ];

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
