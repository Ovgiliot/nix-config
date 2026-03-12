# Shared helpers for Home Manager modules.
# Import with: `homeLib = import ../lib.nix {inherit lib pkgs config;};`
{
  lib,
  pkgs,
  config,
}: {
  # Strip the shebang line produced by shellcheck-compliant scripts so that
  # writeShellApplication can supply its own (strict-mode) header instead.
  stripShebang = text: lib.strings.removePrefix "#!/usr/bin/env bash\n" text;

  # Create a Chromium app-mode .desktop file for a web app.
  # Usage: mkDesktopFile { name = "YouTube"; url = "https://..."; icon = "video-x-generic"; }
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
      Exec=${pkgs.chromium}/bin/chromium --app=${app.url} --class=webapp-${className} --name=webapp-${className} --ozone-platform=wayland --enable-features=WaylandWindowDecorations
      Terminal=false
      Categories=Network;WebBrowser;
      Icon=${app.icon}
    '';
  };
}
