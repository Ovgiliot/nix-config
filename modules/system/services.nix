{ config, pkgs, ... }:

{
  # Power management
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Enable experimental Nix features for flakes
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Automatic Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Essential system packages
  environment.systemPackages = with pkgs; [
    git  # Required for flakes
    vim
  ];

  # Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;
}
