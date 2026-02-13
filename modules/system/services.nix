{ config, pkgs, ... }:

{
  # Power management
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

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
}