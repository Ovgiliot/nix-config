# Workstation profile
# Full desktop (Niri/Wayland) + gaming stack. No laptop-specific power management.
{
  inputs,
  dotfilesDir,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ../modules/system/desktop
    ../modules/system/optional/gaming.nix
    ../modules/system/optional/virtualization.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    chromium.enableWideVine = true;
  };

  # Weekly GC via systemd timer (set here because nix.nix is shared with macOS).
  nix.gc.dates = "weekly";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {inherit inputs dotfilesDir;};
    users.ethel.imports = [
      ../modules/home/core
      ../modules/home/desktop
    ];
  };
}
