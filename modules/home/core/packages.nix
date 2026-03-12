{pkgs, ...}: {
  home.packages = with pkgs; [
    # Fonts
    nerd-fonts.fira-mono

    # CLI / TUI Essentials
    # git: installed via programs.git in core/default.nix — do not add here.
    jq
    ripgrep
    fd
    btop
    lazygit
    ranger
    w3m
    bat
    bitwarden-cli
  ];
}
