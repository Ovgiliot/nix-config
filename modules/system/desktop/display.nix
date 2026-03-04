{
  pkgs,
  lib,
  inputs,
  videoAcceleration,
  primaryUser,
  ...
}: {
  # Niri overlay applied here so pkgs.niri-unstable is available system-wide
  # and in Home Manager (useGlobalPkgs = true).
  nixpkgs.overlays = [inputs.niri.overlays.niri];

  # --- Display & Window Management ---

  # X11 windowing system
  # Disabled for a minimal, Wayland-native setup.
  # XWayland still provides compatibility for legacy apps.
  services.xserver.enable = false;

  # Display Manager (Greetd)
  # Uses tuigreet as a lightweight TUI login manager.
  # initial_session autologins after boot — TPM2 unlocks the disk silently,
  # then greetd starts the Niri session directly (macOS FileVault-style flow).
  # default_session is the fallback when the autologin session exits or fails.
  # swaylock provides session-lock security; run `swaylock` to protect the screen.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "niri-session";
        user = primaryUser;
      };
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

  # Hardware Acceleration
  # extraPackages/extraPackages32 are only populated for Intel; other hosts get
  # an empty list (driver packages are architecture-specific anyway).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = lib.optionals (videoAcceleration == "intel") (with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      vpl-gpu-rt
    ]);
    extraPackages32 = lib.optionals (videoAcceleration == "intel") (with pkgs.pkgsi686Linux; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ]);
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = lib.mkIf (videoAcceleration == "intel") "iHD";
    # Force Chromium, Electron, and all Ozone-aware apps to use the native
    # Wayland rendering path instead of falling back to XWayland.  Without
    # this they go through xwayland-satellite, adding an extra buffer-copy
    # step that introduces timing jitter and contributes to missed vblanks.
    NIXOS_OZONE_WL = "1";
  };
}
