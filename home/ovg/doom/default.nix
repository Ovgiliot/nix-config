{ pkgs, lib, inputs, ... }:

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
  # Since the store is read-only, Doom's internal state must go elsewhere.
  xdg.configFile."emacs".source = inputs.doomemacs;

  # 2. Symlink User Config to ~/.config/doom
  xdg.configFile."doom".source = ./doom.d;

  # 3. Set environment variables so Doom knows where to work
  # DOOMDIR: User configuration
  # DOOMLOCALDIR: Writable directory for packages, bytecode, and cache
  home.sessionVariables = {
    DOOMDIR = "$HOME/.config/doom";
    DOOMLOCALDIR = "$HOME/.local/share/doom";
  };

  # 4. Add the 'doom' binary to PATH and add a convenient alias
  home.shellAliases = {
    doom = "~/.config/emacs/bin/doom";
  };

  # Activation script to ensure the local directory exists
  home.activation.setupDoom = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.local/share/doom
  '';
}
