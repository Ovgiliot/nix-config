# Dashboard workflow — Homepage dashboard for at-a-glance service status.
# Requires services infrastructure (imports Caddy, Prometheus, fail2ban, sops).
#
# Architecture:
#   - Homepage dashboard provides a single-page overview of all services
#   - Binds to localhost on port 8082; Caddy provides TLS at dash.<hostname>.local
#   - Health checks via siteMonitor (HTTP pings) work out of the box
#   - Rich API widgets require per-service API keys — configure these after
#     first deploying each service by adding keys to the environment file:
#     /run/secrets/homepage-env (one KEY=value per line)
#   - Service URLs use localhost since Homepage runs on the same machine
#
# After deploy: visit each service's web UI to generate API keys, then
# add them to secrets/homepage-env.yaml and re-encrypt with sops.
{config, ...}: let
  hostname = config.networking.hostName;
in {
  imports = [
    ../services
  ];

  # ── Secrets (optional — for API key integration) ────────────────────────
  # Homepage reads env vars from this file for widget API keys.
  # Create secrets/homepage-env.yaml with KEY=value pairs, encrypt with sops.
  # Until API keys are configured, health checks still work via siteMonitor.
  sops.secrets."homepage/env" = {
    sopsFile = ../../../secrets/homepage-env;
    format = "dotenv";
  };

  # ── Homepage Dashboard ─────────────────────────────────────────────────
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "dash.${hostname}.local:443,dash.${hostname}.local:8082,localhost:8082,127.0.0.1:8082";

    environmentFiles = [
      config.sops.secrets."homepage/env".path
    ];

    settings = {
      title = "${hostname}";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      layout = {
        Media = {
          style = "row";
          columns = 3;
        };
        Downloads = {
          style = "row";
          columns = 5;
        };
        Services = {
          style = "row";
          columns = 3;
        };
        Monitoring = {
          style = "row";
          columns = 2;
        };
      };
    };

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        datetime = {
          text_size = "xl";
          format = {
            dateStyle = "long";
            timeStyle = "short";
          };
        };
      }
    ];

    services = [
      # ── Media ──
      {
        Media = [
          {
            Jellyfin = {
              icon = "jellyfin.png";
              href = "https://jellyfin.${hostname}.local";
              siteMonitor = "http://127.0.0.1:8096";
              description = "Movies, TV & Music";
              widget = {
                type = "jellyfin";
                url = "http://127.0.0.1:8096";
                key = "{{HOMEPAGE_VAR_JELLYFIN_KEY}}";
                enableBlocks = true;
                enableNowPlaying = true;
              };
            };
          }
          {
            Nextcloud = {
              icon = "nextcloud.png";
              href = "https://nextcloud.${hostname}.local";
              siteMonitor = "http://127.0.0.1:80";
              description = "File sync & collaboration";
              widget = {
                type = "nextcloud";
                url = "https://nextcloud.${hostname}.local";
                key = "{{HOMEPAGE_VAR_NEXTCLOUD_TOKEN}}";
              };
            };
          }
          {
            "Home Assistant" = {
              icon = "home-assistant.png";
              href = "https://home.${hostname}.local";
              siteMonitor = "http://127.0.0.1:8123";
              description = "Smart home";
              widget = {
                type = "homeassistant";
                url = "http://127.0.0.1:8123";
                key = "{{HOMEPAGE_VAR_HASS_TOKEN}}";
              };
            };
          }
        ];
      }

      # ── Downloads ──
      {
        Downloads = [
          {
            Sonarr = {
              icon = "sonarr.png";
              href = "https://sonarr.${hostname}.local";
              siteMonitor = "http://127.0.0.1:8989";
              description = "TV series";
              widget = {
                type = "sonarr";
                url = "http://127.0.0.1:8989";
                key = "{{HOMEPAGE_VAR_SONARR_KEY}}";
              };
            };
          }
          {
            Radarr = {
              icon = "radarr.png";
              href = "https://radarr.${hostname}.local";
              siteMonitor = "http://127.0.0.1:7878";
              description = "Movies";
              widget = {
                type = "radarr";
                url = "http://127.0.0.1:7878";
                key = "{{HOMEPAGE_VAR_RADARR_KEY}}";
              };
            };
          }
          {
            Lidarr = {
              icon = "lidarr.png";
              href = "https://lidarr.${hostname}.local";
              siteMonitor = "http://127.0.0.1:8686";
              description = "Music";
              widget = {
                type = "lidarr";
                url = "http://127.0.0.1:8686";
                key = "{{HOMEPAGE_VAR_LIDARR_KEY}}";
              };
            };
          }
          {
            Prowlarr = {
              icon = "prowlarr.png";
              href = "https://prowlarr.${hostname}.local";
              siteMonitor = "http://127.0.0.1:9696";
              description = "Indexers";
              widget = {
                type = "prowlarr";
                url = "http://127.0.0.1:9696";
                key = "{{HOMEPAGE_VAR_PROWLARR_KEY}}";
              };
            };
          }
          {
            Transmission = {
              icon = "transmission.png";
              href = "https://transmission.${hostname}.local";
              siteMonitor = "http://10.200.1.2:9091";
              description = "Downloads (VPN)";
              widget = {
                type = "transmission";
                url = "http://10.200.1.2:9091";
                username = "transmission";
                password = "{{HOMEPAGE_VAR_TRANSMISSION_PASS}}";
              };
            };
          }
        ];
      }

      # ── Services ──
      {
        Services = [
          {
            "AdGuard Home" = {
              icon = "adguard-home.png";
              href = "https://adguard.${hostname}.local";
              siteMonitor = "http://127.0.0.1:3003";
              description = "DNS filtering";
              widget = {
                type = "adguard";
                url = "http://127.0.0.1:3003";
                username = "{{HOMEPAGE_VAR_ADGUARD_USER}}";
                password = "{{HOMEPAGE_VAR_ADGUARD_PASS}}";
              };
            };
          }
          {
            Bazarr = {
              icon = "bazarr.png";
              href = "https://bazarr.${hostname}.local";
              siteMonitor = "http://127.0.0.1:6767";
              description = "Subtitles";
              widget = {
                type = "bazarr";
                url = "http://127.0.0.1:6767";
                key = "{{HOMEPAGE_VAR_BAZARR_KEY}}";
              };
            };
          }
        ];
      }

      # ── Monitoring ──
      {
        Monitoring = [
          {
            Grafana = {
              icon = "grafana.png";
              href = "https://grafana.${hostname}.local";
              siteMonitor = "http://127.0.0.1:3001";
              description = "Dashboards & metrics";
              widget = {
                type = "grafana";
                url = "http://127.0.0.1:3001";
                username = "{{HOMEPAGE_VAR_GRAFANA_USER}}";
                password = "{{HOMEPAGE_VAR_GRAFANA_PASS}}";
              };
            };
          }
          {
            Prometheus = {
              icon = "prometheus.png";
              href = "https://prometheus.${hostname}.local";
              siteMonitor = "http://127.0.0.1:9090";
              description = "Metrics collection";
              widget = {
                type = "prometheus";
                url = "http://127.0.0.1:9090";
              };
            };
          }
        ];
      }
    ];
  };

  # ── Caddy vhost ────────────────────────────────────────────────────────
  services.caddy.virtualHosts."dash.${hostname}.local" = {
    extraConfig = ''
      tls internal
      import security-headers
      reverse_proxy 127.0.0.1:8082
    '';
  };

  # ── Local DNS ──────────────────────────────────────────────────────────
  networking.hosts."127.0.0.1" = [
    "dash.${hostname}.local"
  ];
}
