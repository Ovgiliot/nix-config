{
  pkgs,
  lib,
  dotfilesDir,
  ...
}: let
  # Strip the shebang line produced by shellcheck-compliant scripts so that
  # writeShellApplication can supply its own (strict-mode) header instead.
  stripShebang = text: lib.strings.removePrefix "#!/usr/bin/env bash\n" text;

  # ---------------------------------------------------------------------------
  # System Maintenance
  # Wrapped as Nix derivations so niri keybinds can call them by name rather
  # than embedding fragile absolute paths inside the raw KDL config file.
  # ---------------------------------------------------------------------------

  nixosRebuild = pkgs.writeShellApplication {
    name = "nixos-rebuild-dotfiles";
    # git must resolve to the Nix-managed binary; sudo/nixos-rebuild are
    # system tools available via the inherited system PATH.
    runtimeInputs = [pkgs.git];
    text = stripShebang (builtins.readFile (dotfilesDir + "/scripts/nixos-rebuild-with-git.sh"));
  };

  updateNixos = pkgs.writeShellApplication {
    name = "update-nixos";
    runtimeInputs = [pkgs.git];
    text = stripShebang (builtins.readFile (dotfilesDir + "/scripts/update.sh"));
  };

  # Opens opencode in the dotfiles repo directory.
  opencodeDotfiles = pkgs.writeShellApplication {
    name = "opencode-dotfiles";
    runtimeInputs = [pkgs.opencode];
    text = ''
      cd "$HOME/dotfiles/nix-config"
      exec opencode
    '';
  };

  # ---------------------------------------------------------------------------
  # Idle / Session Management
  # Extracted from the niri config.kdl spawn-sh-at-startup one-liner so the
  # idle policy is readable, diffable, and has declared runtime dependencies.
  # ---------------------------------------------------------------------------

  niriIdle = pkgs.writeShellApplication {
    name = "niri-idle";
    # swaylock, niri, and systemctl are provided by home-manager / the system
    # profile and inherit via the prefixed PATH; only non-obvious deps listed.
    runtimeInputs = with pkgs; [swayidle brightnessctl];
    text = ''
      exec swayidle -w \
        timeout 300  'brightnessctl -s set 10%' \
        resume       'brightnessctl -r' \
        timeout 600  'swaylock -f' \
        timeout 900  'niri msg action power-off-monitors' \
        timeout 1800 'systemctl hibernate' \
        before-sleep 'swaylock -f'
    '';
  };

  # ---------------------------------------------------------------------------
  # Web App Launchers
  # Replaces the fragile grep/sed/xargs pipeline in binds.kdl with a
  # declarative Nix-built script that directly invokes the correct chromium
  # command (matching web-apps.nix exactly).
  # ---------------------------------------------------------------------------

  appleMusic = pkgs.writeShellApplication {
    name = "apple-music";
    runtimeInputs = [pkgs.chromium];
    text = ''
      exec chromium \
        --app=https://music.apple.com \
        --class=webapp-Apple-Music \
        --name=webapp-Apple-Music \
        --ozone-platform=wayland \
        --enable-features=WaylandWindowDecorations
    '';
  };

  # ---------------------------------------------------------------------------
  # Menu Scripts (previously coupled to quickshell.nix)
  # Moved here so the niri keybind dependency is explicit: removing quickshell
  # no longer silently breaks the Mod+Ctrl+{N,B,S} and Mod+P binds.
  # ---------------------------------------------------------------------------

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

  # ---------------------------------------------------------------------------
  # Hardware Toggles
  # ---------------------------------------------------------------------------

  toggleTouchpad = pkgs.writeShellApplication {
    name = "toggle-touchpad";
    runtimeInputs = with pkgs; [libnotify gnugrep];
    text = ''
      for name_file in /sys/class/input/input*/name; do
        if grep -q "Synaptics" "$name_file"; then
          inhibited="$(dirname "$name_file")/inhibited"
          current=$(cat "$inhibited")
          if [ "$current" = "0" ]; then
            echo 1 > "$inhibited"
            notify-send -t 2000 "Touchpad" "Disabled"
          else
            echo 0 > "$inhibited"
            notify-send -t 2000 "Touchpad" "Enabled"
          fi
          exit 0
        fi
      done
      notify-send -t 2000 "Touchpad" "Device not found"
    '';
  };
in {
  home.packages = [
    nixosRebuild
    updateNixos
    opencodeDotfiles
    niriIdle
    appleMusic
    wifiMenu
    btMenu
    powerMenu
    audioMenu
    toggleTouchpad
  ];
}
