{...}: {
  # Hostname
  networking.hostName = "nixos";

  # Enable NetworkManager for easy network management
  networking.networkmanager.enable = true;

  # Firewall is enabled by default; add ports here only if explicitly needed.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
}
