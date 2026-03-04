{
  pkgs,
  dotfilesDir,
  ...
}: {
  home.packages = [pkgs.qutebrowser];
  xdg.configFile."qutebrowser/config.py".source = dotfilesDir + "/qutebrowser/config.py";
}
