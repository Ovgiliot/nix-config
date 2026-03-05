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
      cd "$HOME/dotfiles/nix"
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
    runtimeInputs = with pkgs; [bluez wofi libnotify coreutils gnugrep gnused];
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
  # Color Theming
  # Runs matugen against the active wallpaper and reloads all apps.
  # Wallpaper source: ~/.config/wallpaper.jpg — written by set-wallpaper.
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
    updateColors
  ];
}
