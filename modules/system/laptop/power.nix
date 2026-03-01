{
  config,
  lib,
  swapLuksUuid,
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
  boot.kernelParams = [
    "intel_pstate=active"
    "resume=/dev/mapper/luks-${swapLuksUuid}"
  ];

  boot.resumeDevice = "/dev/mapper/luks-${swapLuksUuid}";

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
