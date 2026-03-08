{pkgs, ...}: {
  imports = [./web-apps.nix];

  home.packages = with pkgs; [
    # Wayland / Desktop Utilities
    xwayland-satellite # X11 app support in Niri
    wofi
    mako
    wl-clipboard
    grim # Screenshot tool
    slurp # Screen area selector
    kanata # Keyboard remapping (homerow mods)
    brightnessctl
    swayidle
    # swaylock-effects: same binary/PAM name as swaylock, adds fractional-scale support
    swaylock-effects
    playerctl # Media control (for niri)
    pulsemixer # Audio control

    # GUI Applications
    bitwarden-cli
    pandoc
    ghostty

    musescore # Music notation software
  ];
}
