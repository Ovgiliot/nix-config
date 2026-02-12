{ config, ... }:

{
  # Hostname
  networking.hostName = "nixos";

  # Enable NetworkManager for easy network management
  networking.networkmanager.enable = true;

  # Firewall configuration (currently permissive)
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
}
