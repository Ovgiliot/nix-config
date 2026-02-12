{ config, pkgs, ... }:

{
  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # LUKS encryption setup
  boot.initrd.luks.devices."luks-9de9918d-99aa-4f0d-8a35-22af09cf8049".device = 
    "/dev/disk/by-uuid/9de9918d-99aa-4f0d-8a35-22af09cf8049";
}
