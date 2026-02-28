{
  pkgs,
  dotfilesDir,
  ...
}: {
  xdg.configFile."wofi/config".source = dotfilesDir + "/wofi/config";
  xdg.configFile."wofi/style.css".source = dotfilesDir + "/wofi/style.css";

  # Menu scripts compiled into the PATH so niri binds can invoke them directly.
  home.packages = [
    (pkgs.writeShellScriptBin "wifi-menu" (builtins.readFile (dotfilesDir + "/wofi/scripts/wifi-menu.sh")))
    (pkgs.writeShellScriptBin "bluetooth-menu" (builtins.readFile (dotfilesDir + "/wofi/scripts/bluetooth-menu.sh")))
    (pkgs.writeShellScriptBin "power-menu" (builtins.readFile (dotfilesDir + "/wofi/scripts/power-menu.sh")))
  ];
}
