# Shared UEFI boot configuration for all profiles.
# Enables systemd-boot, EFI variable writes, systemd-based initrd (required for
# TPM2 auto-unlock), and TPM 2.0 support.
{...}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Systemd-based initrd — required for TPM2 auto-unlock via systemd-cryptenroll.
  # NixOS translates boot.initrd.luks.devices into crypttab entries automatically;
  # the existing LUKS setup continues to work unchanged.
  boot.initrd.systemd.enable = true;

  # TPM 2.0 — exposes the chip to the OS and installs tpm2-tools.
  # Enables: systemd-cryptenroll --tpm2-device=auto (post-install enrollment),
  # and automatic LUKS unlock via TPM2 token at every subsequent boot.
  security.tpm2.enable = true;
}
