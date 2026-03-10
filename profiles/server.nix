# Headless server profile
# Minimal NixOS: core nix/locale/networking + full CLI home config (shell, neovim, tools).
# No display server, audio, or desktop environment.
{
  inputs,
  dotfilesDir,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ../modules/system/core/boot.nix
    ../modules/system/core/nix.nix
    ../modules/system/core/locale.nix
    ../modules/system/core/networking.nix
    ../modules/system/core/security.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Weekly GC via systemd timer (set here because nix.nix is shared with macOS).
  nix.gc.dates = "weekly";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {inherit inputs dotfilesDir;};
    users.ovg.imports = [
      ../modules/home/core
    ];
  };
}
