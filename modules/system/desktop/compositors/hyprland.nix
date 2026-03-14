# Hyprland compositor — dynamic tiling Wayland compositor with scrolling layout.
# Provides: programs.hyprland, portal-hyprland, PAM hyprlock, HM imports.
{pkgs, ...}: {
  # Hyprland compositor.
  programs.hyprland.enable = true;

  # xdg-desktop-portal-hyprland handles screen share/cast on Hyprland.
  # (portal-gtk is provided by the base desktop layer in display.nix)
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-hyprland];
  xdg.portal.config.Hyprland.default = ["hyprland" "gtk"];

  # hyprlock reads PAM to authenticate; without this entry it rejects every password.
  security.pam.services.hyprlock = {};

  home-manager.users.ethel.imports = [
    ../../../home/desktop/compositors/hyprland
  ];
}
