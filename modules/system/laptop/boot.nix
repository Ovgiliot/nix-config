{
  pkgs,
  lib,
  swapLuksUuid,
  ...
}: {
  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use Zen kernel for better responsiveness and gaming
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # LUKS initrd entry for the encrypted swap partition.
  # Only added when swapLuksUuid is non-empty (i.e. swap is LUKS-encrypted).
  # Unencrypted swap or no swap: nothing to add here.
  boot.initrd.luks.devices = lib.optionalAttrs (swapLuksUuid != "") {
    "luks-${swapLuksUuid}".device = "/dev/disk/by-uuid/${swapLuksUuid}";
  };
}
