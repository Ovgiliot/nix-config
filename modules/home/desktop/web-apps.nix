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
      name = "Betaflight";
      url = "https://app.betaflight.com";
      icon = "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse1.mm.bing.net%2Fth%2Fid%2FOIP.wrdMW93WN-mqGwFE1yu8BQAAAA%3Fpid%3DApi&f=1&ipt=4c96b08ab4306ba377bd47d8d4e1c647a6e6667bfcf592b20c7f6096538e277a";
    }
    {
      name = "Nix Packages Search";
      url = "https://search.nixos.org/packages";
      icon = "system-software-install";
    }
    {
      name = "Neuro Karaoke";
      url = "https://neurokaraoke.com";
      icon = "audio-x-generic";
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
      Exec=${webAppBrowser} --app=${app.url} --class=webapp-${className} --name=webapp-${className} --ozone-platform=wayland --enable-features=WaylandWindowDecorations
      Terminal=false
      Categories=Network;WebBrowser;
      Icon=${app.icon}
    '';
  };
in {
  # Declarative web apps (lightweight, uses Chromium app mode)
  home.file = builtins.listToAttrs (map mkDesktopFile webApps);
}
