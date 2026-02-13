{ config, pkgs, ... }:

{
  # Improve boot time entropy generation
  services.haveged.enable = true;

  # Essential system packages
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

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