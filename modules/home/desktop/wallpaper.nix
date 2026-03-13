{pkgs, ...}: {
  # set-wallpaper script lives in quickshell.nix so its Nix store path can be
  # injected into Scripts.qml at build time. This module only manages the swww
  # package and the daemon that must run before any swww img call.
  home.packages = [pkgs.swww];

  # swww-daemon must be running before swww img is called.
  # Starts automatically with the graphical session, mirrors power-monitor pattern.
  systemd.user.services.swww-daemon = {
    Unit = {
      Description = "swww wallpaper daemon";
      After = ["graphical-session.target"];
    };
    Install.WantedBy = ["graphical-session.target"];
    Service = {
      ExecStart = "${pkgs.swww}/bin/swww-daemon";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
