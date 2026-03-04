{
  pkgs,
  dotfilesDir,
  ...
}: {
  imports = [./wallpaper.nix];
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
