{
  config,
  lib,
  swapDevice,
  ...
}: {
  # Power management services
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Thermald for Intel CPUs to prevent overheating and optimize performance
  services.thermald.enable = true;

  # Fan control for ThinkPads
  services.thinkfan.enable = true;

  # Intel-specific optimizations
  # Enable Hardware P-States (HWP)
  boot.kernelParams =
    ["intel_pstate=active"]
    # resume= is only needed when a swap device is available for hibernation.
    ++ lib.optionals (swapDevice != "") ["resume=${swapDevice}"];

  # Hibernate resume device.
  # swapDevice is set per-host in hosts/<hostname>/default.nix:
  #   encrypted swap → "/dev/mapper/cryptswap"
  #   unencrypted swap → "/dev/disk/by-uuid/<partUuid>"
  #   no swap / non-laptop → ""  (this module is not imported in that case)
  boot.resumeDevice = lib.mkIf (swapDevice != "") swapDevice;

  # ThinkPad specific battery management
  boot.extraModulePackages = with config.boot.kernelPackages; [
    acpi_call
  ];
  boot.kernelModules = ["acpi_call"];

  # Powertop auto-tune for additional power savings on battery
  powerManagement.powertop.enable = true;

  # Ensure the scaling governor is set to powersave (required for intel_pstate)
  # The actual scaling is controlled by the EPP hints via power-profiles-daemon
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
