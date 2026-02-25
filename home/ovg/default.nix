{ config, pkgs, inputs, ... }:

let
  # --- Appearance Colors ---
  bg = "#131314";
  fg = "#e6edf3";
  accent = "#2f81f7";
  accent_fg = "#ffffff";
  header_bg = "#1a1a1b";
  card_bg = "#1d1d1e";
in
{
  # Import user-specific modules
  imports = [
    ./web-apps.nix
  ];

  # --- User Profile Information ---
  home.username = "ovg";
  home.homeDirectory = "/home/ovg";
  home.stateVersion = "25.11";

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # --- XDG & Application Management ---
  xdg.enable = true;

  # Custom Desktop Entry for Steam with Optimizations
  xdg.desktopEntries.steam = {
    name = "Steam";
    exec = "steam -cef-disable-gpu -system-composer %U";
    terminal = false;
    icon = "steam";
    type = "Application";
    categories = [ "Network" "FileTransfer" "Game" ];
    mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
  };

  # --- User Packages (The Suckless Selection) ---
  home.packages = with pkgs; [
    # Desktop Environment & Wayland Utilities
    xwayland-satellite  # X11 app support in Niri
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    waybar              # Status bar
    wofi                # App launcher
    mako                # Notifications
    wl-clipboard        # Clipboard utility
    grim                # Screenshot tool
    slurp               # Screen area selector
    kanata              # Keyboard remapping (homerow mods)
    brightnessctl       # Screen brightness
    swayidle            # Idle management
    swaylock            # Screen locker
    playerctl           # Media control (for waybar/niri)
    linux-wallpaperengine # Live wallpapers
    
    # Fonts
    nerd-fonts.jetbrains-mono

    # CLI / TUI Essentials (Minimal Power Tools)
    gemini-cli          # AI Assistant
    jq                  # JSON processor
    ripgrep             # Search utility
    fd                  # Find utility
    btop                # System monitor
    lazygit             # Git TUI
    ranger              # File manager
    ueberzugpp          # Image previews for ranger
    w3m                 # Terminal browser
    bat                 # Better 'cat' with syntax highlighting
    
    # GUI Applications (Kept minimal)
    bitwarden-cli       # Vault management (Suckless CLI version)
    pandoc              # Document converter
    ghostty             # Terminal emulator
    protontricks        # Winetricks for Proton (Gaming)

    # Ranger Preview Dependencies
    ffmpeg
    ffmpegthumbnailer
    atool
    p7zip
    unzip
    highlight
    exiftool
    librsvg

    # Custom Menu Scripts
    (pkgs.writeShellScriptBin "wifi-menu" (builtins.readFile ./wofi/scripts/wifi-menu.sh))
    (pkgs.writeShellScriptBin "bluetooth-menu" (builtins.readFile ./wofi/scripts/bluetooth-menu.sh))
    (pkgs.writeShellScriptBin "power-menu" (builtins.readFile ./wofi/scripts/power-menu.sh))

    # --- Development Stack ---
    # General Tools
    gnumake gcc cmake automake autoconf libtool
    gdb sqlite
    
    # Language Servers & Formatters
    lua-language-server stylua
    nixd alejandra
    clang-tools
    bash-language-server shfmt shellcheck
    nodejs # Required for many LSPs
    
    # Graphics Development
    glslang 
    
    # .NET Development
    omnisharp-roslyn netcoredbg
  ];

  # --- Appearance & Theme (GTK / QT) ---
  gtk = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraCss = ''
      @define-color window_bg_color ${bg};
      @define-color window_fg_color ${fg};
      @define-color headerbar_bg_color ${header_bg};
      @define-color headerbar_fg_color ${fg};
      @define-color card_bg_color ${card_bg};
      @define-color accent_bg_color ${accent};
      @define-color accent_fg_color ${accent_fg};
    '';
    gtk4.extraCss = ''
      @define-color window_bg_color ${bg};
      @define-color window_fg_color ${fg};
      @define-color headerbar_bg_color ${header_bg};
      @define-color headerbar_fg_color ${fg};
      @define-color card_bg_color ${card_bg};
      @define-color accent_bg_color ${accent};
      @define-color accent_fg_color ${accent_fg};
    '';
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # --- Core Applications Configuration ---

  # Git Identity
  programs.git = {
    enable = true;
    settings.user = {
      name = "Ovgiliot";
      email = "ovgiliot@gmail.com";
    };
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  # Neovim (Primary Editor)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Shell Configuration (Aliases for productivity)
  programs.fish = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
      clean-nix = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +10 && sudo nix-collect-garbage -d";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
      clean-nix = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +10 && sudo nix-collect-garbage -d";
    };
  };

  # Performance HUD for Games
  programs.mangohud = {
    enable = true;
    enableSessionWide = false;
  };

  # --- XDG Config Linkage ---
  # These point to local directories and files in this repository.
  xdg.configFile."niri".source = ./niri;
  xdg.configFile."nvim".source = ./nvim;
  xdg.configFile."kanata/kanata.kbd".source = ./kanata.kbd;
  xdg.configFile."ghostty/config".source = ./ghostty/config;
  xdg.configFile."ghostty/shaders".source = ./ghostty/shaders;
  xdg.configFile."ranger/rc.conf".source = ./ranger/rc.conf;
  xdg.configFile."ranger/rifle.conf".source = ./ranger/rifle.conf;
  xdg.configFile."ranger/scope.sh".source = ./ranger/scope.sh;
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;
  xdg.configFile."waybar/scripts".source = ./waybar/scripts;
  xdg.configFile."wofi/config".source = ./wofi/config;
  xdg.configFile."wofi/style.css".source = ./wofi/style.css;
  xdg.configFile."mako/config".source = ./mako/config;

  # --- Background Services (User Level) ---
  services.network-manager-applet.enable = true;

  # Power Monitor Service: 
  # Automatically manages power profiles (performance/balanced/power-saver)
  # based on AC status and battery percentage.
  systemd.user.services.power-monitor = {
    Unit = {
      Description = "Intelligent Power Profile Management";
      After = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      ExecStart = pkgs.writeShellScript "power-monitor" ''
        # Find battery and AC devices
        BAT=$( ${pkgs.upower}/bin/upower -e | ${pkgs.gnugrep}/bin/grep -E 'battery_BAT[0-9]' | ${pkgs.coreutils}/bin/head -n 1 )
        AC=$( ${pkgs.upower}/bin/upower -e | ${pkgs.gnugrep}/bin/grep -E 'line_power|AC|ADP' | ${pkgs.coreutils}/bin/head -n 1 )

        # Helper functions
        get_battery_percent() {
          if [ -n "$BAT" ]; then
            ${pkgs.upower}/bin/upower -i "$BAT" | ${pkgs.gnugrep}/bin/grep 'percentage' | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.coreutils}/bin/tr -d '%'
          fi
        }

        is_on_ac() {
          if [ -n "$AC" ]; then
            ${pkgs.upower}/bin/upower -i "$AC" | ${pkgs.gnugrep}/bin/grep 'online' | ${pkgs.gawk}/bin/awk '{print $2}'
          else
            echo "no"
          fi
        }

        set_profile() {
          new_profile="$1"
          current=$(${pkgs.power-profiles-daemon}/bin/powerprofilesctl get)
          if [ "$current" != "$new_profile" ]; then
            if ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set "$new_profile"; then
               ${pkgs.libnotify}/bin/notify-send -u normal "Power Profile" "Switched to $new_profile"
            fi
          fi
        }

        while true; do
          # Check for user overrides in /tmp
          if [ -f /tmp/power_profile_override ]; then
            OVERRIDE=$(cat /tmp/power_profile_override)
            if [ "$OVERRIDE" = "auto" ]; then
              rm /tmp/power_profile_override
            elif [ -n "$OVERRIDE" ]; then
               set_profile "$OVERRIDE"
               sleep 60
               continue
            fi
          fi

          AC_STATUS=$(is_on_ac)
          BAT_PERCENT=$(get_battery_percent)

          if [ "$AC_STATUS" = "yes" ]; then
            set_profile "performance"
          elif [ -n "$BAT_PERCENT" ]; then
            if [ "$BAT_PERCENT" -gt 40 ]; then
              set_profile "balanced"
            else
              set_profile "power-saver"
            fi
          else
             set_profile "balanced"
          fi
          
          sleep 60
        done
      '';
      Restart = "always";
      RestartSec = 5;
    };
  };
}
