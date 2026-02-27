{
  pkgs,
  lib,
  ...
}: {
  # --- Display & Window Management ---

  # X11 windowing system
  # Disabled for a minimal, Wayland-native setup.
  # XWayland still provides compatibility for legacy apps.
  services.xserver.enable = false;

  # Display Manager (Greetd)
  # Uses tuigreet as a lightweight TUI login manager.
  # initial_session is intentionally absent: always require authentication.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --greeting 'Suckless NixOS' --asterisks --remember --remember-user-session --time --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # Niri Window Manager
  # A scrollable-tiling Wayland compositor.
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  # XDG desktop portal
  # Essential for Wayland features like screen sharing and file pickers.
  # xdg-desktop-portal-gnome handles screen share/cast on niri.
  # xdg-desktop-portal-wlr is wlroots-only and does not work with niri.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [xdg-desktop-portal-gtk xdg-desktop-portal-gnome];
    config.common.default = ["gnome" "gtk"];
  };

  # --- System Utilities ---

  environment.systemPackages = with pkgs; [
    git
    pciutils
    usbutils
  ];

  # Font configuration
  fonts.packages = with pkgs; [
    pkgs.nerd-fonts."symbols-only"
  ];

  # Chromium - Kept for specific web-app support and DRM.
  programs.chromium.enable = true;

  # --- Legacy & Hardware Services ---

  # Printing support (CUPS)
  # Disabled to reduce background services.
  services.printing.enable = false;

  # Security and session management
  security.rtkit.enable = true;
  security.polkit.enable = true;
  # swaylock reads PAM to authenticate; without this entry it rejects every password.
  security.pam.services.swaylock = {};

  # Hardware Acceleration (Intel)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      vpl-gpu-rt
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    XDG_CONFIG_DIRS = lib.mkDefault "/etc/xdg";
  };
}
