{
  config,
  pkgs,
  inputs,
  ...
}: let
  # --- Appearance Colors ---
  bg = "#131314";
  fg = "#e6edf3";
  accent = "#2f81f7";
  accent_fg = "#ffffff";
  header_bg = "#1a1a1b";
  card_bg = "#1d1d1e";
  # --- Shared Shell Aliases ---
  # Defined once here to keep fish and bash in sync.
  commonAliases = {
    ll = "ls -la";
    ".." = "cd ..";
    # Delete profile generations older than 7 days (user + system), then GC.
    # Run the user part first (no sudo), then the system part (sudo).
    clean-nix = "nix-collect-garbage --delete-older-than 7d && sudo nix-collect-garbage --delete-older-than 7d";
  };

  # --- Shared GTK3 / GTK4 CSS Theme Variables ---
  # Defined once to keep GTK3 and GTK4 in sync.
  gtkCss = ''
    @define-color window_bg_color ${bg};
    @define-color window_fg_color ${fg};
    @define-color headerbar_bg_color ${header_bg};
    @define-color headerbar_fg_color ${fg};
    @define-color card_bg_color ${card_bg};
    @define-color accent_bg_color ${accent};
    @define-color accent_fg_color ${accent_fg};
  '';
in {
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
    categories = ["Network" "FileTransfer" "Game"];
    mimeType = ["x-scheme-handler/steam" "x-scheme-handler/steamlink"];
  };

  # --- User Packages (The Suckless Selection) ---
  home.packages = with pkgs; [
    # Desktop Environment & Wayland Utilities
    xwayland-satellite # X11 app support in Niri
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    waybar # Status bar
    wofi # App launcher
    mako # Notifications
    wl-clipboard # Clipboard utility
    grim # Screenshot tool
    slurp # Screen area selector
    kanata # Keyboard remapping (homerow mods)
    brightnessctl # Screen brightness
    swayidle # Idle management
    # swaylock is managed via programs.swaylock below (config + package)
    playerctl # Media control (for waybar/niri)
    linux-wallpaperengine # Live wallpapers

    # Fonts
    nerd-fonts.jetbrains-mono

    # CLI / TUI Essentials (Minimal Power Tools)
    opencode # OpenCode AI Assistant
    jq # JSON processor
    ripgrep # Search utility
    fd # Find utility
    btop # System monitor
    lazygit # Git TUI
    ranger # File manager
    ueberzugpp # Image previews for ranger
    w3m # Terminal browser
    bat # Better 'cat' with syntax highlighting

    # GUI Applications (Kept minimal)
    bitwarden-cli # Vault management (Suckless CLI version)
    pandoc # Document converter
    ghostty # Terminal emulator
    protontricks # Winetricks for Proton (Gaming)

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
    gnumake
    gcc
    cmake
    automake
    autoconf
    libtool
    gdb
    sqlite

    # Language Servers & Formatters
    lua-language-server
    stylua
    nixd
    alejandra
    clang-tools
    bash-language-server
    shfmt
    shellcheck
    nodejs # Required for many LSPs

    # Graphics Development
    glslang

    # .NET Development
    omnisharp-roslyn
    netcoredbg
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
    gtk3.extraCss = gtkCss;
    gtk4.extraCss = gtkCss;
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
  # All plugins declared here so Nix manages the full plugin set — single source of truth.
  # Treesitter parsers must come from Nix on NixOS (compiled .so files; :TSInstall cannot
  # compile at runtime on an immutable filesystem).
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      # Treesitter + parsers
      (nvim-treesitter.withPlugins (p: [
        p.c
        p.cpp
        p.lua
        p.vim
        p.vimdoc
        p.query
        p.markdown
        p.markdown_inline
        p.nix
        p.bash
        p.fish
        p.c_sharp
        p.glsl
        p.hlsl
        # org is not available in nixpkgs grammarPlugins; orgmode ships its own parser
      ]))

      # Theme & UI
      github-nvim-theme
      lualine-nvim
      nvim-web-devicons
      which-key-nvim

      # Telescope
      telescope-nvim
      plenary-nvim
      telescope-fzf-native-nvim
      telescope-ui-select-nvim

      # File Management
      ranger-nvim # kelly-lin/ranger.nvim (francoiscabrol/ranger.vim is not in nixpkgs)

      # Org Mode
      orgmode
      org-roam-nvim
      sqlite-lua
      headlines-nvim
      # org-bullets-nvim: not in nixpkgs, cosmetic only — omitted

      # Git
      neogit
      diffview-nvim

      # AI
      copilot-vim
      snacks-nvim
      opencode-nvim

      # LSP
      nvim-lspconfig

      # Completion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      cmp_luasnip
      luasnip
      friendly-snippets

      # Formatting
      conform-nvim

      # Linting
      nvim-lint

      # Debugging
      nvim-dap
      nvim-dap-ui
      nvim-nio

      # Autosave
      auto-save-nvim
    ];
  };

  # Shell Configuration (Aliases for productivity)
  programs.fish = {
    enable = true;
    shellAliases = commonAliases;
  };

  programs.bash = {
    enable = true;
    shellAliases = commonAliases;
  };

  # Performance HUD for Games
  programs.mangohud = {
    enable = true;
    enableSessionWide = false;
  };

  # Screen Locker (themed to match the colour palette)
  # The config here generates ~/.config/swaylock/config.
  # swayidle in niri/config.kdl invokes 'swaylock -f'.
  programs.swaylock = {
    enable = true;
    settings = {
      color = "131314";
      font = "JetBrainsMono Nerd Font";
      font-size = 16;
      indicator-radius = 80;
      indicator-thickness = 8;
      line-color = "131314";
      ring-color = "2f81f7";
      inside-color = "1d1d1e";
      key-hl-color = "2f81f7";
      separator-color = "00000000";
      text-color = "e6edf3";
      bs-hl-color = "ff3333";
      ring-wrong-color = "ff3333";
      text-wrong-color = "ff3333";
      inside-wrong-color = "1d1d1e";
      line-wrong-color = "ff3333";
      inside-clear-color = "1d1d1e";
      text-clear-color = "e6edf3";
      ring-clear-color = "2f81f7";
      line-clear-color = "131314";
      show-failed-attempts = true;
    };
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

  # Global OpenCode agent: 'talk' — web-search-only agent available in any project.
  # Placed in ~/.config/opencode/agents/ so opencode picks it up globally.
  xdg.configFile."opencode/agents/talk.md".source = ./opencode/agents/talk.md;

  # --- Background Services (User Level) ---
  services.network-manager-applet.enable = true;

  # Power Monitor Service:
  # Automatically manages power profiles (performance/balanced/power-saver)
  # based on AC status and battery percentage.
  # The script lives in scripts/power-monitor.sh; pkgs.writeShellApplication
  # wraps it with a strict PATH containing only the declared runtimeInputs.
  systemd.user.services.power-monitor = let
    powerMonitor = pkgs.writeShellApplication {
      name = "power-monitor";
      runtimeInputs = with pkgs; [
        upower
        gnugrep
        gawk
        coreutils
        power-profiles-daemon
        libnotify
      ];
      text = builtins.readFile ./scripts/power-monitor.sh;
    };
  in {
    Unit = {
      Description = "Intelligent Power Profile Management";
      After = ["graphical-session.target"];
    };
    Install.WantedBy = ["graphical-session.target"];
    Service = {
      ExecStart = "${powerMonitor}/bin/power-monitor";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
