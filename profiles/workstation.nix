# Workstation profile
# Full desktop (Niri/Wayland) + gaming stack. No laptop-specific power management.
{
  inputs,
  dotfilesDir,
  ...
}: {
  imports = [
    inputs.niri.nixosModules.niri
    inputs.home-manager.nixosModules.home-manager
    ../modules/system/core/nix.nix
    ../modules/system/core/locale.nix
    ../modules/system/core/networking.nix
    ../modules/system/desktop/audio.nix
    ../modules/system/desktop/display.nix
    ../modules/system/desktop/input.nix
    ../modules/system/optional/gaming.nix
  ];

  nixpkgs.overlays = [inputs.niri.overlays.niri];
  nixpkgs.config = {
    allowUnfree = true;
    chromium.enableWideVine = true;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {inherit inputs dotfilesDir;};
    users.ovg.imports = [
      ../modules/home/core
      ../modules/home/desktop
    ];
  };
}
