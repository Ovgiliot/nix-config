{
  pkgs,
  inputs,
  ...
}: {
  imports = [./web-apps.nix];

  home.packages = with pkgs; [
    # Wayland / Desktop Utilities
    xwayland-satellite # X11 app support in Niri
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    wofi
    mako
    wl-clipboard
    grim # Screenshot tool
    slurp # Screen area selector
    kanata # Keyboard remapping (homerow mods)
    brightnessctl
    swayidle
    playerctl # Media control (for niri)
    pulsemixer # Audio control
    linux-wallpaperengine # Live wallpapers

    # GUI Applications
    bitwarden-cli
    pandoc
    ghostty
    protontricks # Winetricks for Proton (Gaming)
  ];

  # Performance HUD for Games
  programs.mangohud = {
    enable = true;
    enableSessionWide = false;
  };

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
}
