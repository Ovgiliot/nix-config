{ config, pkgs, lib, inputs, ... }:

{
  # Install Emacs and essential Doom dependencies
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk; # Optimal for Wayland/Niri
  };

  home.packages = with pkgs; [
    git
    ripgrep
    fd
    findutils
    binutils
    gnumake
    cmake
    emacs-all-the-icons-fonts
  ];

  # 1. Symlink Doom core from Nix store to ~/.config/emacs
  xdg.configFile."emacs".source = inputs.doomemacs;

  # 2. Symlink User Config to ~/.config/doom
  xdg.configFile."doom".source = ./doom.d;

  # 3. Set environment variables to force Doom to use writable paths
  # EMACSDIR: Must be set to the symlink path, NOT the resolved Nix store path
  # DOOMDIR: Your configuration
  # DOOMLOCALDIR: Where packages and cache will live
  home.sessionVariables = {
    EMACSDIR = "${config.home.homeDirectory}/.config/emacs";
    DOOMDIR = "${config.home.homeDirectory}/.config/doom";
    DOOMLOCALDIR = "${config.home.homeDirectory}/.local/share/doom";
  };

  # 4. Update alias to ensure variables are always present
  home.shellAliases = {
    doom = "EMACSDIR=${config.home.homeDirectory}/.config/emacs DOOMDIR=${config.home.homeDirectory}/.config/doom DOOMLOCALDIR=${config.home.homeDirectory}/.local/share/doom ${config.home.homeDirectory}/.config/emacs/bin/doom";
  };

  # Ensure the local directory exists before Doom tries to use it
  home.activation.setupDoom = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.home.homeDirectory}/.local/share/doom
  '';
}