{dotfilesDir, ...}: {
  xdg.configFile."niri".source = dotfilesDir + "/niri";
}
