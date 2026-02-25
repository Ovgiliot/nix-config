{ config, pkgs, ... }:

{
  # Haveged is generally not needed on modern kernels (5.6+)
  services.haveged.enable = false;

  # Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;

  # Firmware update service
  services.fwupd.enable = true;

  # SSD maintenance
  services.fstrim.enable = true;

  # zram for better performance on 8GB RAM
  zramSwap.enable = true;
}
