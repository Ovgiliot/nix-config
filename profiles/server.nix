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
    ../modules/system/core/nix.nix
    ../modules/system/core/locale.nix
    ../modules/system/core/networking.nix
  ];

  nixpkgs.config.allowUnfree = true;

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
