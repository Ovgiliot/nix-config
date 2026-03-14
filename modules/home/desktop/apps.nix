{pkgs, ...}: {
  home.packages = with pkgs; [
    # Wayland / Desktop Utilities
    wofi
    mako
    wl-clipboard
    grim # Screenshot tool
    slurp # Screen area selector
    kanata # Keyboard remapping (homerow mods)
    brightnessctl
    playerctl # Media control
    pulsemixer # Audio control
    ghostty
    pcmanfm # Lightweight file manager / file picker
    # Compositor-specific packages (xwayland-satellite, swayidle, hyprlock, etc.)
    # live in their respective compositor modules under compositors/.
  ];
}
