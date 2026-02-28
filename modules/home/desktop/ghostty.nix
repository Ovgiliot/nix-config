{dotfilesDir, ...}: {
  xdg.configFile."ghostty/config".source = dotfilesDir + "/ghostty/config";
  xdg.configFile."ghostty/shaders".source = dotfilesDir + "/ghostty/shaders";
}
