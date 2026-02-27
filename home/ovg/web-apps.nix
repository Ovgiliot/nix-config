{
  config,
  pkgs,
  ...
}: let
  webAppBrowser = "${pkgs.chromium}/bin/chromium";
  webApps = [
    # { name = "app-name"; url = "https://example.com"; icon = "app-icon"; }
    # Icons must exist in the active icon theme (Adwaita).
    # Use `gtk4-icon-browser` or `xdg-open` to verify icon names.
    {
      name = "YouTube";
      url = "https://www.youtube.com";
      icon = "video-x-generic";
    }
    {
      name = "Apple Music";
      url = "https://music.apple.com";
      icon = "audio-x-generic";
    }
    {
      name = "Nix Packages Search";
      url = "https://search.nixos.org/packages";
      icon = "system-software-install";
    }
  ];

  mkDesktopFile = app: let
    className = builtins.replaceStrings [" "] ["-"] app.name;
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
