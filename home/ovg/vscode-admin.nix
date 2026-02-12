{ config,
 pkgs,
... }:

let
  # Wrapper that launches VS Code as root via pkexec
  codeRoot = pkgs.writeShellScriptBin "code-root" ''
    exec ${pkgs.polkit}/bin/pkexec \
      env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY \
      ${pkgs.vscode}/bin/code "$@"
  '';

  # Normal VS Code launcher
  vscodeDesktop = pkgs.makeDesktopItem {
    name = "vscode";
    desktopName = "Visual Studio Code";
    exec = "${pkgs.vscode}/bin/code %F";
    icon = "code";
    categories = [ "Development" "IDE" ];
    terminal = false;
    startupWMClass = "Code";
  };

  # Elevated VS Code launcher
  vscodeRootDesktop = pkgs.makeDesktopItem {
    name = "vscode-root";
    desktopName = "Visual Studio Code (Admin)";
    exec = "${codeRoot}/bin/code-root %F";
    icon = "code";
    categories = [ "Development" "IDE" ];
    terminal = false;
    startupWMClass = "Code";
  };
in
{
  # VS Code desktop entries and admin launcher
  home.packages = [
    codeRoot
    vscodeDesktop
    vscodeRootDesktop
  ];
}
