# Media server workflow — Jellyfin for streaming movies, TV shows, and music.
# Requires services infrastructure (imports Caddy, Prometheus, fail2ban, sops).
#
# Jellyfin binds to localhost; Caddy provides TLS-terminated access at
# jellyfin.<hostname>.local. Media libraries are configured per-host via
# the mediaLibraryDirs specialArg.
{
  config,
  mediaLibraryDirs,
  ...
}: let
  hostname = config.networking.hostName;
in {
  imports = [
    ../services
  ];

  # ── Jellyfin ───────────────────────────────────────────────────────────
  services.jellyfin = {
    enable = true;
    # Default data dir: /var/lib/jellyfin
    # Media libraries are added via the web UI on first run, pointing to
    # paths from mediaLibraryDirs (bind-mounted or symlinked by the host).
  };

  # Bind Jellyfin to localhost — Caddy handles external access.
  # The NixOS Jellyfin module already applies systemd hardening (ProtectSystem,
  # PrivateTmp, NoNewPrivileges, etc.). We only add ReadWritePaths for media.
  systemd.services.jellyfin.serviceConfig.ReadWritePaths = mediaLibraryDirs;

  # ── Caddy vhost ────────────────────────────────────────────────────────
  services.caddy.virtualHosts."jellyfin.${hostname}.local" = {
    extraConfig = ''
      tls internal
      reverse_proxy 127.0.0.1:8096
      import security-headers
    '';
  };

  # ── Local DNS ──────────────────────────────────────────────────────────
  networking.hosts."127.0.0.1" = [
    "jellyfin.${hostname}.local"
  ];
}
