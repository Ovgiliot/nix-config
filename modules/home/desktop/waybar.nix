{dotfilesDir, ...}: {
  xdg.configFile."waybar/config".source = dotfilesDir + "/waybar/config.jsonc";
  xdg.configFile."waybar/style.css".source = dotfilesDir + "/waybar/style.css";
  xdg.configFile."waybar/scripts".source = dotfilesDir + "/waybar/scripts";
}
