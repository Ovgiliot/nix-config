# Laptop home — power monitor, kanata link, wallpaper, touchpad toggle.
# Imports desktop as a dependency (which imports core).
{
  pkgs,
  lib,
  dotfilesDir,
  ...
}: let
  toggleTouchpad = pkgs.writeShellApplication {
    name = "toggle-touchpad";
    runtimeInputs = with pkgs; [libnotify gnugrep];
    text = ''
      for name_file in /sys/class/input/input*/name; do
        if grep -q "Synaptics" "$name_file"; then
          inhibited="$(dirname "$name_file")/inhibited"
          current=$(cat "$inhibited")
          if [ "$current" = "0" ]; then
            echo 1 > "$inhibited"
            notify-send -t 2000 "Touchpad" "Disabled"
          else
            echo 0 > "$inhibited"
            notify-send -t 2000 "Touchpad" "Enabled"
          fi
          exit 0
        fi
      done
      notify-send -t 2000 "Touchpad" "Device not found"
    '';
  };
in {
  imports = [
    ../desktop
    ./wallpaper.nix
  ];
  home.packages = [toggleTouchpad];

  # Kanata config link (system-level kanata service reads from ~/.config/kanata/)
  xdg.configFile."kanata/kanata.kbd".source = dotfilesDir + "/kanata.kbd";

  # Power Monitor Service:
  # Automatically manages power profiles (performance/balanced/power-saver)
  # based on AC status and battery percentage.
  # pkgs.writeShellApplication wraps it with a strict PATH of declared runtimeInputs.
  systemd.user.services.power-monitor = let
    powerMonitor = pkgs.writeShellApplication {
      name = "power-monitor";
      runtimeInputs = with pkgs; [
        coreutils
        power-profiles-daemon
        libnotify
      ];
      text = builtins.readFile (dotfilesDir + "/scripts/power-monitor.sh");
    };
  in {
    Unit = {
      Description = "Intelligent Power Profile Management";
      After = ["graphical-session.target"];
    };
    Install.WantedBy = ["graphical-session.target"];
    Service = {
      ExecStart = "${powerMonitor}/bin/power-monitor";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
