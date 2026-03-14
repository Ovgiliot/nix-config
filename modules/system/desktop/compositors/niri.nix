# Niri compositor — scrollable-tiling Wayland compositor.
# Extracted from the desktop layer so compositors are composable modules.
# Provides: niri overlay, programs.niri, portal-gnome, PAM swaylock, HM imports.
{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.niri.nixosModules.niri
  ];

  # Niri overlay so pkgs.niri-unstable is available system-wide
  # and in Home Manager (useGlobalPkgs = true).
  nixpkgs.overlays = [inputs.niri.overlays.niri];

  # Niri Window Manager
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  # xdg-desktop-portal-gnome handles screen share/cast on niri.
  # (portal-gtk is provided by the base desktop layer in display.nix)
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gnome];
  xdg.portal.config.niri.default = ["gnome" "gtk"];

  # swaylock reads PAM to authenticate; without this entry it rejects every password.
  security.pam.services.swaylock = {};

  home-manager.users.ethel.imports = [
    ../../../home/desktop/compositors/niri
  ];
}
