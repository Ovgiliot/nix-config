# Laptop-specific boot settings (ThinkPad).
# The shared bootloader, systemd initrd, and TPM2 config live in core/boot.nix
# and are imported by the laptop profile.
{
  pkgs,
  lib,
  swapLuksUuid,
  ...
}: {
  # Use Zen kernel for better responsiveness and gaming
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # LUKS initrd entry for the encrypted swap partition.
  # Only added when swapLuksUuid is non-empty (i.e. swap is LUKS-encrypted).
  # Unencrypted swap or no swap: nothing to add here.
  boot.initrd.luks.devices = lib.optionalAttrs (swapLuksUuid != "") {
    "luks-${swapLuksUuid}".device = "/dev/disk/by-uuid/${swapLuksUuid}";
  };

  # Disable Intel PSR (Panel Self-Refresh) on Kaby Lake.
  # PSR2 selective-fetch causes region-localised flicker: when one window updates
  # while another is static, the PSR state machine transitions during the dirty-
  # region commit produce a visible flash inside the updating window.
  # Kaby Lake (HD 620, device 0x5917) has well-documented PSR2 errata on Linux.
  # Power regression is negligible — the display is never fully static at runtime
  # (linux-wallpaperengine keeps refreshing the background continuously).
  #
  # PCI hotplug resource reservation for Thunderbolt.
  # T480 BIOS under-allocates I/O and prefetchable memory for Thunderbolt hotplug
  # bridges. Without this, downstream PCIe devices behind a dock (xHCI USB, etc.)
  # fail with "bridge window can't assign; no space" and the tunneled USB controller
  # dies on resume. hpiosize/hpmmiosize/hpmmioprefsize tell the kernel to reserve
  # enough address space for hot-added Thunderbolt PCIe endpoints.
  boot.kernelParams = [
    "i915.enable_psr=0"
    "pci=hpiosize=0x4000,hpmmiosize=0x4000000,hpmmioprefsize=0x4000000"
  ];
}
