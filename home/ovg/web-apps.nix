{ config, pkgs, ... }:

let
  webAppBrowser = "${pkgs.chromium}/bin/chromium";
  webApps = [
    # { name = "app-name"; url = "https://example.com"; icon = "app-icon"; }
    { name = "YouTube"; url = "https://www.youtube.com"; icon = "youtube"; }
    { name = "Apple Music"; url = "https://music.apple.com"; icon = "apple-music"; }
    { name = "Nix Packages Search"; url = "https://search.nixos.org/packages"; icon = "nix"; }
  ];

  mkDesktopFile = app: let
    className = builtins.replaceStrings [ " " ] [ "-" ] app.name;
    fileName = "webapp-${className}.desktop";
  in {
    name = "${config.xdg.dataHome}/applications/${fileName}";
    value.text = ''
      [Desktop Entry]
      Version=1.5
      Type=Application
      Name=${app.name}
      Comment=Web app: ${app.url}
      Exec=${webAppBrowser} --app=${app.url} --class=webapp-${className} --name=webapp-${className}
      Terminal=false
      Categories=Network;WebBrowser;
      Icon=${app.icon}
    '';
  };

in {
  # Declarative web apps (lightweight, uses Chromium app mode)
  home.file = builtins.listToAttrs (map mkDesktopFile webApps);
}
