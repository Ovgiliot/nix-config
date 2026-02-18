{ config, pkgs, inputs, ... }:

let
  # Ghostty colors
  bg = "#131314";
  fg = "#e6edf3";
  accent = "#2f81f7";
  accent_fg = "#ffffff";
  header_bg = "#1a1a1b";
  card_bg = "#1d1d1e";
in
{
  imports = [
    ./web-apps.nix
  ];

  # Home Manager information
  home.username = "ovg";
  home.homeDirectory = "/home/ovg";
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # XDG configuration
  xdg.enable = true;
  xdg.desktopEntries.steam = {
    name = "Steam";
    exec = "steam -cef-disable-gpu -system-composer %U";
    terminal = false;
    icon = "steam";
    type = "Application";
    categories = [ "Network" "FileTransfer" "Game" ];
    mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
  };

  # User packages - GUI applications and development tools
  home.packages = with pkgs; [
    # Environment packages
    xwayland-satellite # For X11 app support in niri
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    waybar
    wofi
    mako
    wl-clipboard
    grim
    slurp
    gemini-cli
    jq
    kanata # For homerow mods
    brightnessctl # For screen brightness control
    swayidle # For idle management (screen dimming, locking)
    swaylock # Screen locker
    ripgrep # grep utility for telescope
    fd # find utility for telescope

    # GUI applications
    playerctl # Required for media key bindings in Niri
    bitwarden-desktop
    pandoc
    thunar
    ghostty
    linux-wallpaperengine
    protontricks

    # Ranger previewers
    ffmpeg
    ffmpegthumbnailer
    poppler-utils
    atool
    p7zip
    unzip
    odt2txt
    ghostscript
    imagemagick
    python3Packages.pygments
    bat
    highlight
    exiftool
    librsvg
    catdoc
    xlsx2csv

    (pkgs.writeShellScriptBin "wifi-menu" (builtins.readFile ./wofi/scripts/wifi-menu.sh))
    (pkgs.writeShellScriptBin "bluetooth-menu" (builtins.readFile ./wofi/scripts/bluetooth-menu.sh))

    # Development Tools
    lua-language-server
    stylua
    nixd
    alejandra
    clang-tools
    gdb
    sqlite
    
    # Shell / Scripting
    bash-language-server
    shfmt
    shellcheck

    # Graphics
    glslang # For GLSL validation
    
    # C# / .NET
    omnisharp-roslyn
    netcoredbg
  ];

  # Theme configuration
  gtk = {
    enable = true;
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

  # Dark mode preference for GTK4/LibAdwaita
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Ovgiliot";
        email = "ovgiliot@gmail.com";
      };
    };
  };

  # Neovim configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Shell configuration
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

  programs.mangohud = {
    enable = true;
    enableSessionWide = false;
  };

  # XDG Config Sources
  xdg.configFile."niri".source = ./niri;
  xdg.configFile."nvim".source = ./nvim;
  xdg.configFile."kanata/kanata.kbd".source = ./kanata.kbd;
  xdg.configFile."ghostty/config".source = ./ghostty/config;
  xdg.configFile."ghostty/shaders".source = ./ghostty/shaders;
  xdg.configFile."ranger/rc.conf".source = ./ranger/rc.conf;
  xdg.configFile."ranger/scope.sh".source = ./ranger/scope.sh;
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;
  xdg.configFile."wofi/config".source = ./wofi/config;
  xdg.configFile."wofi/style.css".source = ./wofi/style.css;
  xdg.configFile."mako/config".source = ./mako/config;

  services.network-manager-applet.enable = true;
}
