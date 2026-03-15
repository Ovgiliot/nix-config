# Nextcloud workflow — self-hosted file sync, calendar, contacts.
# Requires services infrastructure (imports Caddy, Prometheus, fail2ban, sops).
#
# Architecture:
#   - Nextcloud runs behind Caddy (TLS-terminated) at nextcloud.<hostname>.local
#   - PostgreSQL backend (auto-created by the NixOS module via database.createLocally)
#   - Redis for file locking and transactional caching (Unix socket, no TCP)
#   - Admin password from sops-nix secrets
#   - The NixOS module's built-in nginx is disabled (mkForce); Caddy speaks FastCGI
#     directly to the PHP-FPM socket, eliminating the double-proxy overhead
#   - PHP-FPM socket ownership is changed to caddy for direct access
#
# Secrets required in secrets.yaml:
#   nextcloud/admin-password — Initial admin account password
{
  config,
  pkgs,
  lib,
  serviceDataDir,
  ...
}: let
  hostname = config.networking.hostName;
  nextcloudDomain = "nextcloud.${hostname}.local";
  nextcloudHome = config.services.nextcloud.home;
  fpmSocket = config.services.phpfpm.pools.nextcloud.socket;
in {
  imports = [
    ../services
  ];

  # ── Secrets ────────────────────────────────────────────────────────────
  sops.secrets."nextcloud/admin-password" = {
    owner = "nextcloud";
    group = "nextcloud";
    mode = "0400";
  };

  # ── Nextcloud ──────────────────────────────────────────────────────────
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud30;
    hostName = nextcloudDomain;
    https = true; # Tell Nextcloud it's behind HTTPS (Caddy terminates TLS)

    # Data directory — configurable per host via serviceDataDir.
    datadir = "${serviceDataDir}/nextcloud";

    # Max upload size — generous default for file sync.
    maxUploadSize = "10G";

    # Let the NixOS module create PostgreSQL DB + user automatically.
    database.createLocally = true;

    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = config.sops.secrets."nextcloud/admin-password".path;
    };

    # Redis for distributed caching and transactional file locking.
    configureRedis = true;

    settings = {
      # Trust only the local Caddy reverse proxy.
      trusted_proxies = ["127.0.0.1"];
      overwriteprotocol = "https";

      # Maintenance window for background jobs (2-5 AM local time).
      maintenance_window_start = 2;

      # Default phone region for phone number validation.
      default_phone_region = "US";

      # Logging
      log_type = "file";
      loglevel = 2; # Warning
    };

    # PHP performance tuning
    phpOptions = {
      "opcache.interned_strings_buffer" = "16";
      "opcache.max_accelerated_files" = "10000";
      "opcache.memory_consumption" = "128";
      "opcache.revalidate_freq" = "1";
    };
  };

  # ── Redis ──────────────────────────────────────────────────────────────
  # Unix socket only — no TCP exposure. Owned by nextcloud user.
  services.redis.servers.nextcloud = {
    enable = true;
    user = "nextcloud";
    port = 0;
  };

  # ── Disable the NixOS module's built-in nginx ──────────────────────────
  # The Nextcloud module sets services.nginx.enable = true internally.
  # We override with mkForce since Caddy handles everything.
  services.nginx.enable = lib.mkForce false;

  # ── PHP-FPM socket ownership ───────────────────────────────────────────
  # The module sets listen.owner/group to nginx by default. Caddy needs
  # direct access to the PHP-FPM socket.
  services.phpfpm.pools.nextcloud.settings = {
    "listen.owner" = config.services.caddy.user;
    "listen.group" = config.services.caddy.group;
  };

  # ── Grant Caddy access to Nextcloud's webroot and data ─────────────────
  # Caddy serves static files directly and needs read access to the
  # Nextcloud home directory (store-apps, nix-apps).
  users.groups.nextcloud.members = ["nextcloud" config.services.caddy.user];

  # ── Caddy vhost ────────────────────────────────────────────────────────
  # Caddy speaks FastCGI directly to the PHP-FPM socket. No nginx in the path.
  services.caddy.virtualHosts.${nextcloudDomain} = {
    extraConfig = ''
      tls internal

      encode zstd gzip

      root * ${config.services.nextcloud.package}

      # Apps installed via extraApps (nix-apps) and the app store (store-apps)
      # live under the Nextcloud home directory, not the package derivation.
      root /store-apps/* ${nextcloudHome}
      root /nix-apps/* ${nextcloudHome}

      # Well-known redirects for CalDAV, CardDAV, WebFinger, NodeInfo
      redir /.well-known/carddav /remote.php/dav 301
      redir /.well-known/caldav /remote.php/dav 301
      redir /.well-known/webfinger /index.php/.well-known/webfinger 301
      redir /.well-known/nodeinfo /index.php/.well-known/nodeinfo 301
      redir /.well-known/* /index.php{uri} 301
      redir /remote/* /remote.php{uri} 301

      # FastCGI to PHP-FPM — the core of the Caddy↔Nextcloud integration.
      # front_controller_active and modHeadersAvailable tell Nextcloud that
      # the webserver handles routing and headers (no .htaccess needed).
      php_fastcgi unix/${fpmSocket} {
        root ${config.services.nextcloud.package}
        env front_controller_active true
        env modHeadersAvailable true
      }

      # Security headers (Nextcloud-specific, stricter than the global snippet)
      header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        Permissions-Policy "interest-cohort=()"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        Referrer-Policy "no-referrer"
        X-Robots-Tag "noindex, nofollow"
        -X-Powered-By
        -Server
      }

      # Block access to sensitive paths
      @forbidden {
        path /build/* /tests/* /config/* /lib/* /3rdparty/* /templates/* /data/*
        path /.* /autotest* /occ* /issue* /indie* /db_* /console*
        not path /.well-known/*
      }
      error @forbidden 404

      # Immutable versioned static assets (long cache)
      @immutable {
        path *.css *.js *.mjs *.svg *.gif *.png *.jpg *.ico *.wasm *.tflite
        query v=*
      }
      header @immutable Cache-Control "max-age=15778463, immutable"

      # Unversioned static assets
      @static {
        path *.css *.js *.mjs *.svg *.gif *.png *.jpg *.ico *.wasm *.tflite
        not query v=*
      }
      header @static Cache-Control "max-age=15778463"

      @woff2 path *.woff2
      header @woff2 Cache-Control "max-age=604800"

      file_server
    '';
  };

  # ── Local DNS ──────────────────────────────────────────────────────────
  networking.hosts."127.0.0.1" = [
    nextcloudDomain
  ];

  # ── Fail2ban jail for Nextcloud ────────────────────────────────────────
  # Nextcloud logs failed logins to its own log file.
  services.fail2ban.jails.nextcloud = {
    settings = {
      enabled = true;
      backend = "auto";
      maxretry = 5;
      findtime = "10m";
      bantime = "1h";
      logpath = "${nextcloudHome}/data/nextcloud.log";
    };
    filter.Definition = {
      failregex = ''^.*Login failed: .*Remote IP.*<ADDR>.*$'';
      ignoreregex = "";
    };
  };
}
