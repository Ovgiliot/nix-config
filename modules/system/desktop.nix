{ config, pkgs, inputs, lib, ... }:

{
  # X11 windowing system
  services.xserver.enable = true;

  # Display Manager (Greetd with Autologin)
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "niri-session";
        user = "ovg";
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --greeting 'Welcome to NixOS' --asterisks --remember --remember-user-session --time --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # Niri Window Manager
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  # Neovim (system-wide) with lazy.nvim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  environment.systemPackages = with pkgs; [
    btop # i need to nonitor the system
    git
    gh
    ranger
    nodejs
    gcc
  ];

  fonts.packages = with pkgs; [
    pkgs.nerd-fonts."symbols-only"
  ];
  
  # Keyboard layout
  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    options = "grp:alt_shift_toggle,caps:escape";
  };

  # Chromium (needed for Widevine DRM for Apple Music web)
  programs.chromium.enable = true;

  # System-wide Neovim config (XDG)
  environment.etc."xdg/nvim/init.lua".source = ./nvim/init.lua;

  # Ensure /etc/xdg is part of config search path
  environment.sessionVariables.XDG_CONFIG_DIRS = lib.mkDefault "/etc/xdg";

  # Printing support
  services.printing.enable = true;


  # Security and polkit
  security.rtkit.enable = true;
  security.polkit.enable = true;
}
