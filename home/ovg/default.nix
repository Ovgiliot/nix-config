{ config, pkgs, inputs, ... }:

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

  # User packages - GUI applications and development tools
  home.packages = with pkgs; [
    # Environment packages
    xwayland-satellite # For X11 app support in niri
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    wofi
    mako
    wl-clipboard
    grim
    slurp
    gemini-cli
    jq
    kanata # For homerow mods

    # GUI applications
    playerctl # Required for media key bindings in Niri
    bitwarden-desktop
    obsidian
    thunar
    ghostty
  ];

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

  # XDG Config Sources
  xdg.configFile."niri".source = ./niri;
  xdg.configFile."nvim".source = ./nvim;
  xdg.configFile."kanata/kanata.kbd".source = ./kanata.kbd;
  xdg.configFile."ghostty/config".source = ./ghostty/config;
  xdg.configFile."ghostty/shaders".source = ./ghostty/shaders;
}
