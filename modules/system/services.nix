{...}: {
  # Bluetooth support
  hardware.bluetooth = {
    enable = true;
    # Don't power on at boot — saves battery on a laptop.
    # Enable manually or via the bluetooth-menu script when needed.
    powerOnBoot = false;
  };

  services.blueman.enable = true;

  # Firmware update service
  services.fwupd.enable = true;

  # SSD maintenance
  services.fstrim.enable = true;

  # zram for better performance on 8GB RAM
  zramSwap.enable = true;
}
