{...}: {
  imports = [
    ./theme.nix
    ./niri.nix
    ./quickshell.nix
    ./ghostty.nix
    ./notifications.nix
    ./launcher.nix
    ./apps.nix
  ];

  services.network-manager-applet.enable = true;
}
