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
  # Color Theming
  # Defined here (not in scripts.nix) so setWallpaper can reference it as a
  # runtimeInputs entry, which embeds the correct store path in the wrapper's
  # PATH prefix — avoiding the fragile ~/.nix-profile/bin/ hardcode.
  # ---------------------------------------------------------------------------

  updateColors = pkgs.writeShellApplication {
    name = "update-colors";
    # ghostty/mako/niri reloads are handled by per-template post_hooks in
    # matugen's config.toml. Only tools that need special orchestration stay here.
    runtimeInputs = with pkgs; [matugen procps glib neovim];
    text = ''
      WALLPAPER="$HOME/.config/wallpaper.jpg"
      if [ ! -f "$WALLPAPER" ]; then
        echo "update-colors: no wallpaper at $WALLPAPER — run set-wallpaper first" >&2
        exit 1
      fi

      # Generate all templates. Per-template post_hooks (ghostty, mako, niri)
      # run automatically after each file is written.
      matugen image "$WALLPAPER" --mode dark --type scheme-content

      # GTK — toggle theme name to force running GTK apps to re-read CSS.
      # Needs sleep between the two calls so the theme switch is detected.
      gsettings set org.gnome.desktop.interface gtk-theme Adwaita
      sleep 0.1
      gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark

      # Qutebrowser — re-source config only if an instance is already running.
      # Without the guard, ':config-source' launches a new window when no
      # instance exists.
      if pgrep -x qutebrowser > /dev/null 2>&1; then
        qutebrowser ':config-source' 2>/dev/null || true
      fi

      # Neovim — reload highlight colours in all running instances.
      UID_VAL=$(id -u)
      for sock in /run/user/"$UID_VAL"/nvim.*.0; do
        [ -S "$sock" ] && \
          nvim --server "$sock" \
            --remote-expr 'execute("luafile ~/.cache/matugen/nvim-hl-colors.lua")' \
          2>/dev/null || true &
      done

      wait
    '';
  };

  # set-wallpaper: standalone CLI — lists updateColors as runtimeInputs so the
  # Nix wrapper prepends its store bin/ to PATH without hardcoded profile paths.
  # swww img is guarded with || true (no-op when swww-daemon is absent).
  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper";
    runtimeInputs = with pkgs; [swww coreutils imagemagick updateColors];
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
      # Convert to a real JPEG regardless of source format so matugen can
      # always decode it (matugen infers the codec from the file extension).
      convert "$SRC" "$HOME/.config/wallpaper.jpg"
      # Apply via swww (no-op when swww-daemon is absent).
      swww img "$HOME/.config/wallpaper.jpg" --transition-type random || true
      # Regenerate colour scheme to match the new wallpaper.
      update-colors
    '';
  };

  scriptsQml = ''
    pragma Singleton

    import Quickshell

    // Singleton so there is one instance shared across all components.
    // All paths are absolute Nix store paths — no PATH dependency at runtime.
    Singleton {
        readonly property string wifiMonitor: "${wifiMonitor}/bin/wifi-monitor"
        readonly property string status:      "${status}/bin/status"
        readonly property string getPower:    "${getPower}/bin/get-power-profile"
        // Absolute store path avoids relying on PATH in the systemd user service
        // environment — used by Workspaces to dispatch focus-workspace actions.
        readonly property string niri:                  "${pkgs.niri}/bin/niri"
        readonly property string qsColors:              "file:///home/ovg/.cache/matugen/qs-colors.json"
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
    cp ${dotfilesDir}/quickshell/WifiMonitor.qml        $out/WifiMonitor.qml
    cp ${dotfilesDir}/quickshell/Colors.qml             $out/Colors.qml
    cp ${pkgs.writeText "Scripts.qml" scriptsQml}       $out/Scripts.qml
  '';
in {
  # quickshell + color theming + set-wallpaper CLI (available on all desktops;
  # swww img in set-wallpaper is a graceful no-op when swww-daemon is absent).
  home.packages = [
    pkgs.quickshell
    updateColors
    setWallpaper
  ];

  # Single directory link — all QML files (including generated Scripts.qml) live
  # in one store path so QML module resolution finds siblings after symlink resolution.
  xdg.configFile."quickshell".source = shellConfig;

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell status bar";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
      # Cap restarts: max 10 in 120 s to avoid permanently dying after a
      # transient compositor hiccup, while still preventing tight crash loops.
      StartLimitIntervalSec = 120;
      StartLimitBurst = 10;
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
