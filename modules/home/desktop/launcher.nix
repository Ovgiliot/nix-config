{dotfilesDir, ...}: {
  xdg.configFile."wofi/config".source = dotfilesDir + "/wofi/config";
  xdg.configFile."wofi/style.css".source = dotfilesDir + "/wofi/style.css";
}
