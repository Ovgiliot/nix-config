# Hyprland home module — XDG config, hyprland-specific packages.
{
  pkgs,
  dotfilesDir,
  ...
}: {
  # Hyprland raw dotfiles (hyprland.conf, hypridle.conf, hyprlock.conf).
  xdg.configFile."hypr".source = dotfilesDir + "/hypr";

  home.packages = [
    pkgs.hyprlock # Screen locker for Hyprland
    pkgs.hypridle # Idle daemon for Hyprland
    pkgs.xwayland-satellite # X11 app support
    pkgs.jq # Used by screenshot-window keybind (hyprctl JSON parsing)
  ];
}
