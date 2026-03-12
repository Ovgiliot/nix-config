{...}: {
  # hostname is declared per-host in hosts/<name>/default.nix

  # Enable NetworkManager for easy network management
  networking.networkmanager.enable = true;

  # Use nftables backend (modern replacement for iptables).
  networking.nftables.enable = true;

  # Firewall is enabled by default; add ports here only if explicitly needed.
  networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # Randomize Wi-Fi MAC address per connection to prevent tracking.
  networking.networkmanager.wifi.macAddress = "random";
}
