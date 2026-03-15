# DNS filtering workflow — AdGuard Home for network-wide ad/tracker blocking.
# Requires services infrastructure (imports Caddy, Prometheus, fail2ban).
#
# AdGuard Home runs as a DNS resolver on port 53 with encrypted upstream DNS.
# Web UI is behind Caddy reverse proxy at adguard.<hostname>.local.
# Settings are declarative with mutableSettings for fine-tuning filters via UI.
{config, ...}: let
  hostname = config.networking.hostName;
in {
  imports = [
    ../services
  ];

  # ── AdGuard Home ─────────────────────────────────────────────────────────
  services.adguardhome = {
    enable = true;
    # Web UI port — accessed via Caddy, not directly.
    port = 3003;
    host = "127.0.0.1";
    # Declarative base config merged with UI changes on each restart.
    mutableSettings = true;
    settings = {
      dns = {
        bind_hosts = ["127.0.0.1"];
        port = 53;
        # Encrypted upstream DNS — Quad9 (security-focused) + Cloudflare (performance).
        upstream_dns = [
          "tls://dns.quad9.net"
          "https://cloudflare-dns.com/dns-query"
        ];
        # Bootstrap DNS for resolving DoH/DoT hostnames during startup.
        bootstrap_dns = [
          "9.9.9.9"
          "1.1.1.1"
        ];
        # Rate limiting: 20 requests/second per client prevents abuse.
        ratelimit = 20;
      };
      filtering = {
        filtering_enabled = true;
        # Block pages show a friendly "blocked" page instead of connection timeout.
        blocking_mode = "default";
      };
      # Default filter lists — AdGuard's curated lists for ads and trackers.
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          name = "AdAway Default Blocklist";
          id = 2;
        }
      ];
    };
  };

  # ── Caddy vhost ────────────────────────────────────────────────────────
  services.caddy.virtualHosts."adguard.${hostname}.local" = {
    extraConfig = ''
      tls internal
      reverse_proxy 127.0.0.1:${toString config.services.adguardhome.port}
      import security-headers
    '';
  };

  # ── Local DNS ──────────────────────────────────────────────────────────
  networking.hosts."127.0.0.1" = [
    "adguard.${hostname}.local"
  ];

  # ── Firewall ───────────────────────────────────────────────────────────
  # DNS on port 53 for local network clients.
  networking.firewall.allowedTCPPorts = [53];
  networking.firewall.allowedUDPPorts = [53];
}
