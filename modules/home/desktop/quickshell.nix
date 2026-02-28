{
  pkgs,
  dotfilesDir,
  ...
}: {
  home.packages = [pkgs.quickshell];

  # Link quickshell QML config
  xdg.configFile."quickshell".source = dotfilesDir + "/quickshell";

  # Keep waybar scripts accessible at ~/.config/waybar/scripts/ (QML files reference them there)
  xdg.configFile."waybar/scripts".source = dotfilesDir + "/waybar/scripts";

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell status bar";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
      RestartSec = "2";
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
