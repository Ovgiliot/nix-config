# Core system infrastructure — every NixOS machine imports this.
# Boot, nix settings, locale, networking, security, home-manager base.
{
  inputs,
  dotfilesDir,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./boot.nix
    ./nix.nix
    ./locale.nix
    ./networking.nix
    ./security.nix
  ];

  # Weekly GC via systemd timer. Set here (not nix.nix) because nix.nix is
  # shared with darwin, which uses launchd intervals instead.
  nix.gc.dates = "weekly";

  # Home Manager base configuration — shared across all NixOS profiles.
  # Individual profiles/workflows add to users.ethel.imports; the module
  # system merges the lists.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {inherit inputs dotfilesDir;};
    users.ethel.imports = [
      ../../home/core
    ];
  };
}
