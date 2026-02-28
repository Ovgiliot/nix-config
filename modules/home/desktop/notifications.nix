{dotfilesDir, ...}: {
  xdg.configFile."mako/config".source = dotfilesDir + "/mako/config";
}
