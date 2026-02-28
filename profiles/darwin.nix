# macOS profile (nix-darwin + home-manager)
# Core nix settings + full CLI + desktop apps managed by nix.
# System-level macOS preferences via nix-darwin; no Wayland/display server config.
{
  inputs,
  dotfilesDir,
  ...
}: {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ../modules/system/core/nix.nix
    ../modules/system/core/locale.nix
  ];

  # Required on macOS: nix-daemon runs as a system service
  services.nix-daemon.enable = true;

  nixpkgs.config.allowUnfree = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {inherit inputs dotfilesDir;};
    users.ovg.imports = [
      ../modules/home/core
      ../modules/home/desktop
      ../modules/home/darwin
    ];
  };
}
