# macOS profile (nix-darwin + home-manager)
# Core nix settings + full CLI. No Wayland/display server config (macOS-specific
# desktop config lives in modules/home/darwin).
{
  inputs,
  dotfilesDir,
  ...
}: {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ../modules/system/core/nix.nix
    # locale.nix is intentionally excluded: i18n.* options are NixOS-only.
    # macOS locale is managed via System Settings.
  ];

  # Required on macOS: nix-daemon runs as a system service
  services.nix-daemon.enable = true;

  # Weekly garbage collection via launchd (macOS equivalent of nix.gc.dates).
  nix.gc.interval = {
    Hour = 3;
    Minute = 0;
    Weekday = 0;
  };

  nixpkgs.config.allowUnfree = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {inherit inputs dotfilesDir;};
    users.ovg.imports = [
      ../modules/home/core
      ../modules/home/darwin
    ];
  };
}
