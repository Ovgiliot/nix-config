# Headless server profile
# Minimal NixOS: core nix/locale/networking + full CLI home config (shell, neovim, tools).
# Self-hosted services layer: Caddy reverse proxy, Prometheus + Grafana monitoring, fail2ban.
# No display server, audio, or desktop environment.
{...}: {
  imports = [
    ../modules/system/server
    ../modules/system/services
    ../modules/system/workflows/development.nix
    ../modules/system/workflows/dns-filtering.nix
    ../modules/system/workflows/vpn.nix
    ../modules/system/workflows/media-server.nix
    ../modules/system/workflows/media-management.nix
    ../modules/system/workflows/nextcloud.nix
    ../modules/system/workflows/smart-home.nix
    ../modules/system/workflows/dashboard.nix
  ];
}
