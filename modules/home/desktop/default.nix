{...}: {
  imports = [
    ./theme.nix
    ./niri.nix
    ./waybar.nix
    ./ghostty.nix
    ./notifications.nix
    ./launcher.nix
    ./apps.nix
  ];

  services.network-manager-applet.enable = true;
}
