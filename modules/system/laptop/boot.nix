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

  # Systemd-based initrd — required for TPM2 auto-unlock via systemd-cryptenroll.
  # NixOS translates boot.initrd.luks.devices into crypttab entries automatically;
  # the existing LUKS setup continues to work unchanged.
  boot.initrd.systemd.enable = true;

  # LUKS initrd entry for the encrypted swap partition.
  # Only added when swapLuksUuid is non-empty (i.e. swap is LUKS-encrypted).
  # Unencrypted swap or no swap: nothing to add here.
  boot.initrd.luks.devices = lib.optionalAttrs (swapLuksUuid != "") {
    "luks-${swapLuksUuid}".device = "/dev/disk/by-uuid/${swapLuksUuid}";
  };

  # TPM 2.0 — exposes the chip to the OS and installs tpm2-tools.
  # Enables: systemd-cryptenroll --tpm2-device=auto (post-install enrollment),
  # and automatic LUKS unlock via TPM2 token at every subsequent boot.
  security.tpm2.enable = true;

  # Disable Intel PSR (Panel Self-Refresh) on Kaby Lake.
  # PSR2 selective-fetch causes region-localised flicker: when one window updates
  # while another is static, the PSR state machine transitions during the dirty-
  # region commit produce a visible flash inside the updating window.
  # Kaby Lake (HD 620, device 0x5917) has well-documented PSR2 errata on Linux.
  # Power regression is negligible — the display is never fully static at runtime
  # (linux-wallpaperengine keeps refreshing the background continuously).
  boot.kernelParams = ["i915.enable_psr=0"];
}
