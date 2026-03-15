# Services infrastructure layer — shared foundation for self-hosted services.
# Provides: reverse proxy (Caddy), monitoring (Prometheus + Grafana + node-exporter),
# secrets management (sops-nix), fail2ban, and firewall base.
# Requires core only (headless-friendly).
#
# Individual service workflows import this module and independently add:
# - Caddy virtualHosts (NixOS merges the attrset)
# - Prometheus scrapeConfigs (NixOS merges the list)
# - Firewall port openings
# - sops.secrets declarations
# - networking.hosts entries for .local DNS
{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    ../core
    inputs.sops-nix.nixosModules.sops
  ];

  # ── sops-nix base ──────────────────────────────────────────────────────
  # Secrets are decrypted to /run/secrets/ during activation (before services start).
  # Each service workflow declares its own sops.secrets entries with per-service ownership.
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  # Grafana admin password — owned by grafana so the service can read it.
  sops.secrets."grafana/admin-password" = {
    owner = "grafana";
    group = "grafana";
  };

  # Grafana secret key for signing cookies and encrypting datasource credentials.
  sops.secrets."grafana/secret-key" = {
    owner = "grafana";
    group = "grafana";
  };

  # ── Caddy reverse proxy ────────────────────────────────────────────────
  # Single entry point for all web services. Each workflow adds its own virtualHosts.
  # Uses internal TLS (self-signed CA) for .local domains.
  services.caddy = {
    enable = true;
    # Snippet for security headers — imported by each virtualHost.
    extraConfig = ''
      (security-headers) {
        header {
          X-Content-Type-Options nosniff
          X-Frame-Options DENY
          Referrer-Policy strict-origin-when-cross-origin
          -Server
        }
      }
    '';
  };

  # Grafana vhost
  services.caddy.virtualHosts."grafana.${config.networking.hostName}.local" = {
    extraConfig = ''
      tls internal
      reverse_proxy 127.0.0.1:${toString config.services.grafana.settings.server.http_port}
      import security-headers
    '';
  };

  # Prometheus vhost (read-only metrics UI)
  services.caddy.virtualHosts."prometheus.${config.networking.hostName}.local" = {
    extraConfig = ''
      tls internal
      reverse_proxy 127.0.0.1:${toString config.services.prometheus.port}
      import security-headers
    '';
  };

  # Local DNS entries so .local names resolve on this machine.
  # Each service workflow appends its own entries; NixOS merges the lists.
  networking.hosts."127.0.0.1" = [
    "grafana.${config.networking.hostName}.local"
    "prometheus.${config.networking.hostName}.local"
  ];

  # ── Prometheus ─────────────────────────────────────────────────────────
  # Metrics collection. Binds to localhost only — accessed via Caddy or Grafana.
  # Service workflows append to scrapeConfigs; NixOS merges the list.
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {targets = ["127.0.0.1:${toString config.services.prometheus.exporters.node.port}"];}
        ];
      }
      {
        job_name = "caddy";
        static_configs = [{targets = ["127.0.0.1:2019"];}];
      }
    ];
    exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9100;
    };
  };

  # ── Grafana ────────────────────────────────────────────────────────────
  # Dashboards and visualization. Binds to localhost — accessed via Caddy.
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3001;
        domain = "grafana.${config.networking.hostName}.local";
        root_url = "https://grafana.${config.networking.hostName}.local";
        protocol = "http"; # Caddy terminates TLS
      };
      security = {
        admin_user = "admin";
        # Grafana resolves $__file{} at startup — the secret stays out of the Nix store.
        admin_password = "$__file{${config.sops.secrets."grafana/admin-password".path}}";
        secret_key = "$__file{${config.sops.secrets."grafana/secret-key".path}}";
      };
      "auth.anonymous".enabled = false;
      users.allow_sign_up = false;
    };
    provision = {
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          isDefault = true;
        }
      ];
    };
  };

  # ── Fail2ban ───────────────────────────────────────────────────────────
  # Brute-force protection. Service workflows add their own jails.
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "48h";
    };
  };

  # ── Firewall ───────────────────────────────────────────────────────────
  # Open HTTP/HTTPS for Caddy. Service workflows add their own ports.
  networking.firewall.allowedTCPPorts = [80 443];

  # ── Home module ────────────────────────────────────────────────────────
  # Dashboard entries and management scripts.
  home-manager.users.ethel.imports = [
    ../../home/services
  ];
}
