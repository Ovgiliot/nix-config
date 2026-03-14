{
  pkgs,
  lib,
  videoAcceleration,
  primaryUser,
  ...
}: {
  # ── Display & Window Management ──────────────────────────────────────────

  # X11 windowing system
  # Disabled for a minimal, Wayland-native setup.
  # XWayland still provides compatibility for legacy apps.
  services.xserver.enable = false;

  # Display Manager (Greetd)
  # Uses tuigreet as a lightweight TUI login manager.
  # --sessions reads .desktop files from /share/wayland-sessions so greetd
  # discovers all installed compositors (niri, hyprland, etc.) automatically.
  # initial_session autologins after boot — TPM2 unlocks the disk silently,
  # then greetd starts the default compositor (macOS FileVault-style flow).
  # default_session is the fallback when the autologin session exits or fails.
  # Session-lock security is per-compositor (swaylock, hyprlock, etc.).
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = lib.mkDefault "niri-session";
        user = primaryUser;
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --greeting 'Suckless NixOS' --asterisks --remember --remember-user-session --time --sessions /run/current-system/sw/share/wayland-sessions";
        user = "greeter";
      };
    };
  };

  # Expose wayland-sessions .desktop files so tuigreet --sessions can find them.
  environment.pathsToLink = ["/share/wayland-sessions"];

  # XDG desktop portal — base layer.
  # portal-gtk provides file-picker and common portals.
  # Compositor-specific portals (portal-gnome, portal-hyprland) are added by
  # each compositor module. Per-desktop portal routing is set there too.
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.common.default = ["gtk"];
  };

  # ── System Utilities ─────────────────────────────────────────────────────

  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
  ];

  # Font configuration
  fonts.packages = with pkgs; [
    pkgs.nerd-fonts."symbols-only"
    noto-fonts-cjk-sans
  ];

  # Fontconfig fallback chain: FiraMono for Latin/Cyrillic, Noto Sans CJK JP
  # for Japanese (and other CJK) glyphs that FiraMono does not cover.
  fonts.fontconfig.defaultFonts = {
    sansSerif = ["FiraMono Nerd Font" "Noto Sans CJK JP"];
    serif = ["Noto Sans CJK JP"];
    monospace = ["FiraMono Nerd Font" "Noto Sans CJK JP"];
  };

  # Chromium is enabled by the browsing workflow.
  # programs.chromium.enable = true;

  # ── Legacy & Hardware Services ────────────────────────────────────────────

  # Printing support (CUPS)
  # Disabled to reduce background services.
  services.printing.enable = false;

  # Security and session management
  security.rtkit.enable = true;
  security.polkit.enable = true;
  # PAM entries for screen lockers live in compositor modules (swaylock, hyprlock).

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
    # Use Vulkan renderer for GTK4 apps.  The default GL renderer causes
    # popup/menu flickering on niri (upstream niri#3162).  Vulkan avoids
    # the compositor-side buffer-age issue that triggers mispositioned or
    # rapidly-closing popups.
    GSK_RENDERER = "vulkan";
    # Force Qt apps to use native Wayland instead of falling back to
    # XWayland via xwayland-satellite, which has known popup/grab bugs
    # on niri (upstream xwayland-satellite#353).
    QT_QPA_PLATFORM = "wayland";
  };
}
