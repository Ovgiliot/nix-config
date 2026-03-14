{pkgs, ...}: {
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
    # swaylock-effects lives in theme.nix (thematically grouped with GTK/Qt theming)
    playerctl # Media control (for niri)
    pulsemixer # Audio control
    ghostty
    pcmanfm # Lightweight file manager / file picker
  ];
}
