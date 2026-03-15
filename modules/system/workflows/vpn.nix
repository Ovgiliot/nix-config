# VPN workflow — WireGuard point-to-site VPN for remote access to server services.
# Requires services infrastructure (imports Caddy, Prometheus, fail2ban, sops).
#
# Replaces the old home-lab.nix scaffold. Server listens on 51820/UDP.
# Remote clients tunnel into 10.100.0.0/24 and reach all .local services via Caddy.
# Private key stored in sops-nix; peer public keys declared per-host in this file.
#
# Client setup:
#   1. Generate keypair: wg genkey | tee private.key | wg pubkey > public.key
#   2. Add peer below with the public key and a unique /32 IP
#   3. Configure client: Endpoint = <server-ip>:51820, AllowedIPs = 10.100.0.0/24
{config, ...}: {
  imports = [
    ../services
  ];

  # ── Secrets ────────────────────────────────────────────────────────────
  sops.secrets."wireguard/private-key" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # ── WireGuard interface ────────────────────────────────────────────────
  networking.wireguard.interfaces.wg0 = {
    ips = ["10.100.0.1/24"];
    listenPort = 51820;
    privateKeyFile = config.sops.secrets."wireguard/private-key".path;

    # Add peers here as clients are provisioned.
    # Each peer gets a unique /32 within 10.100.0.0/24.
    # Example:
    #   { publicKey = "abc123="; allowedIPs = [ "10.100.0.2/32" ]; }
    peers = [
    ];
  };

  # ── IP forwarding ──────────────────────────────────────────────────────
  # Allow VPN clients to reach services on localhost via the tunnel.
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # ── Firewall ───────────────────────────────────────────────────────────
  networking.firewall.allowedUDPPorts = [51820];
}
