{
  pkgs,
  swapLuksUuid,
  ...
}: {
  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use Zen kernel for better responsiveness and gaming
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # LUKS encryption setup for swap/hibernate partition.
  # UUID is passed in from the host's specialArgs to avoid repetition with power.nix.
  boot.initrd.luks.devices."luks-${swapLuksUuid}".device = "/dev/disk/by-uuid/${swapLuksUuid}";
}
