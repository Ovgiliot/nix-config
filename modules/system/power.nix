{ config, pkgs, lib, ... }:

{
  # Power management services
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Thermald for Intel CPUs to prevent overheating and optimize performance
  services.thermald.enable = true;

  # Dynamic power profile switching script
  systemd.services.dynamic-power-profiles = {
    description = "Dynamic Power Profiles based on battery level and AC status";
    after = [ "power-profiles-daemon.service" "upower.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "power-profile-switcher" ''
        # Find battery and AC devices
        BAT=$( ${pkgs.upower}/bin/upower -e | grep -E 'battery_BAT[0-9]' | head -n 1 )
        AC=$( ${pkgs.upower}/bin/upower -e | grep -E 'line_power|AC|ADP' | head -n 1 )

        # Function to get battery percentage
        get_battery_percent() {
          if [ -n "$BAT" ]; then
            ${pkgs.upower}/bin/upower -i "$BAT" | grep 'percentage' | awk '{print $2}' | tr -d '%'
          fi
        }

        # Function to get AC status
        is_on_ac() {
          if [ -n "$AC" ]; then
            ${pkgs.upower}/bin/upower -i "$AC" | grep 'online' | awk '{print $2}'
          else
            # Fallback if AC device not found
            echo "no"
          fi
        }

        # Function to set power profile
        set_profile() {
          current=$(${pkgs.power-profiles-daemon}/bin/powerprofilesctl get)
          if [ "$current" != "$1" ]; then
            ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set "$1"
          fi
        }

        # Main loop
        while true; do
          AC_STATUS=$(is_on_ac)
          BAT_PERCENT=$(get_battery_percent)

          if [ "$AC_STATUS" = "yes" ]; then
            set_profile "performance"
          elif [ -n "$BAT_PERCENT" ]; then
            if [ "$BAT_PERCENT" -gt 40 ]; then
              set_profile "balanced"
            else
              set_profile "power-saver"
            fi
          else
             # If no battery found, default to balanced if not on AC
             set_profile "balanced"
          fi
          
          sleep 60
        done
      '';
      Restart = "always";
      RestartSec = 10;
    };
  };

  # Intel-specific optimizations
  # Enable Hardware P-States (HWP)
  boot.kernelParams = [ "intel_pstate=active" ];

  # Powertop auto-tune for additional power savings on battery
  powerManagement.powertop.enable = true;
  
  # Ensure the scaling governor is set to powersave (required for intel_pstate)
  # The actual scaling is controlled by the EPP hints via power-profiles-daemon
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}