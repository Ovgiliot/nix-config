# Laptop profile (ThinkPad)
# Full desktop (Niri/Wayland) + ThinkPad-specific power management.
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
    ../modules/system/laptop/boot.nix
    ../modules/system/laptop/power.nix
    ../modules/system/laptop/services.nix
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
      ../modules/home/laptop
    ];
  };
}
