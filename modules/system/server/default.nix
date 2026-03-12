# Server infrastructure — headless, hardened kernel.
# Imports core as a dependency.
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../core
  ];

  # Hardened kernel as default — workflows like gaming can override
  # with a higher-priority (lower number) setting.
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_hardened;
}
