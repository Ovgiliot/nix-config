{ config, pkgs, inputs, lib, ... }:

{
  # X11 windowing system (Keep for compatibility/drivers)
  services.xserver.enable = true;

  # Display Manager (Greetd with Autologin)
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "niri-session";
        user = "ovg";
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --greeting 'Welcome to NixOS' --asterisks --remember --remember-user-session --time --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # Niri Window Manager
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  # XDG desktop portal for Wayland file pickers
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-wlr ];
    config = {
      common = {
        default = [ "gtk" "wlr" ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    btop # system monitor
    gh
    lazygit
    ranger
    ueberzugpp
    w3m
    nodejs
    gcc
  ];

  fonts.packages = with pkgs; [
    pkgs.nerd-fonts."symbols-only"
  ];
  
  # Chromium (needed for Widevine DRM for Apple Music web)
  programs.chromium.enable = true;

  # Ensure /etc/xdg is part of config search path
  environment.sessionVariables.XDG_CONFIG_DIRS = lib.mkDefault "/etc/xdg";

  # Printing support
  services.printing.enable = true;

  # Security and polkit
  security.rtkit.enable = true;
  security.polkit.enable = true;

  # Hardware Graphics (OpenGL/Vulkan)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but good fallback)
      libvdpau-va-gl
      vpl-gpu-rt # For newer Intel GPUs (Gen11+) VPL/QSV
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
