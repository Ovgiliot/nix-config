# Media management workflow — *arr stack + Transmission behind a Mullvad VPN namespace.
# Requires services infrastructure (imports Caddy, Prometheus, fail2ban, sops).
#
# Architecture:
#   - Sonarr, Radarr, Lidarr, Prowlarr, Bazarr run in the default namespace
#   - Transmission runs inside a dedicated "vpn" network namespace
#   - The vpn namespace has only a Mullvad WireGuard tunnel as its internet exit
#   - A veth pair (10.200.1.1 ↔ 10.200.1.2) bridges *arr → Transmission RPC
#   - Kill switch is architectural: if Mullvad drops, Transmission has zero connectivity
#   - All services share a "media" group for filesystem access to download/library dirs
#
# Secrets required in secrets.yaml:
#   mullvad/private-key  — Mullvad WireGuard private key
#   mullvad/address      — Mullvad assigned IP (e.g. "10.66.x.x/32")
#   transmission/rpc-password — Transmission web UI / RPC password
{
  config,
  pkgs,
  lib,
  mediaLibraryDirs,
  ...
}: let
  hostname = config.networking.hostName;

  # Mullvad endpoint — Stockholm relay. Change to preferred location.
  mullvadEndpoint = "185.213.154.68:51820";
  mullvadPublicKey = "GHwCt40sOKDAR9GhVREJj1GbMFjFx3JOSChIkOCzV0k=";
  mullvadDns = "10.64.0.1";

  # veth pair addresses for namespace bridging
  vethHostAddr = "10.200.1.1/24";
  vethVpnAddr = "10.200.1.2/24";
  transmissionRpcAddr = "10.200.1.2";
in {
  imports = [
    ../services
  ];

  # ── Shared media group ─────────────────────────────────────────────────
  # All *arr services and Transmission share this group for media directory access.
  users.groups.media = {};

  # ── Secrets ────────────────────────────────────────────────────────────
  sops.secrets."mullvad/private-key" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };
  sops.secrets."mullvad/address" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };
  sops.secrets."transmission/rpc-password" = {
    owner = "transmission";
    group = "media";
    mode = "0440";
  };

  # Generate JSON credentials file from sops secret for Transmission.
  # The credentialsFile expects JSON that gets merged with settings.
  systemd.services.transmission-credentials = {
    description = "Generate Transmission RPC credentials file";
    before = ["transmission.service"];
    requiredBy = ["transmission.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      PASSWORD=$(cat ${config.sops.secrets."transmission/rpc-password".path})
      mkdir -p /run/transmission
      printf '{"rpc-password":"%s"}\n' "$PASSWORD" > /run/transmission/credentials.json
      chown transmission:media /run/transmission/credentials.json
      chmod 440 /run/transmission/credentials.json
    '';
  };

  # ── VPN namespace setup ────────────────────────────────────────────────
  # Creates a network namespace with Mullvad WireGuard as the only internet exit.
  # The veth pair allows *arr services to reach Transmission's RPC.
  systemd.services.vpn-namespace = {
    description = "Mullvad VPN network namespace for isolated downloads";
    before = ["transmission.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.iproute2 pkgs.wireguard-tools];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -e

      # Read secrets
      MULLVAD_KEY=$(cat ${config.sops.secrets."mullvad/private-key".path})
      MULLVAD_ADDR=$(cat ${config.sops.secrets."mullvad/address".path})

      # Create namespace
      ip netns add vpn 2>/dev/null || true

      # Create WireGuard interface in init namespace (for UDP socket on physical NIC),
      # then move it to the vpn namespace. WireGuard remembers the birth namespace
      # for its UDP socket — this is the standard WireGuard namespace trick.
      ip link add wg-mullvad type wireguard 2>/dev/null || true

      # Write ephemeral WireGuard config
      WG_CONF=$(mktemp)
      cat > "$WG_CONF" <<WGEOF
      [Interface]
      PrivateKey = $MULLVAD_KEY

      [Peer]
      PublicKey = ${mullvadPublicKey}
      Endpoint = ${mullvadEndpoint}
      AllowedIPs = 0.0.0.0/0
      WGEOF
      wg setconf wg-mullvad "$WG_CONF"
      rm -f "$WG_CONF"

      # Move WireGuard into the vpn namespace
      ip link set wg-mullvad netns vpn

      # Configure WireGuard inside vpn namespace
      ip -n vpn addr add "$MULLVAD_ADDR" dev wg-mullvad
      ip -n vpn link set wg-mullvad up
      ip -n vpn link set lo up
      ip -n vpn route add default dev wg-mullvad

      # Write DNS config for the namespace
      mkdir -p /etc/netns/vpn
      echo "nameserver ${mullvadDns}" > /etc/netns/vpn/resolv.conf

      # Create veth pair for *arr ↔ Transmission communication
      ip link add veth-host type veth peer name veth-vpn 2>/dev/null || true
      ip link set veth-vpn netns vpn

      # Configure veth-host (default namespace side)
      ip addr add ${vethHostAddr} dev veth-host 2>/dev/null || true
      ip link set veth-host up

      # Configure veth-vpn (vpn namespace side)
      ip -n vpn addr add ${vethVpnAddr} dev veth-vpn 2>/dev/null || true
      ip -n vpn link set veth-vpn up
    '';
    preStop = ''
      ip link del veth-host 2>/dev/null || true
      ip netns del vpn 2>/dev/null || true
      rm -rf /etc/netns/vpn
    '';
  };

  # ── Transmission ───────────────────────────────────────────────────────
  # BitTorrent client, isolated in the vpn namespace.
  services.transmission = {
    enable = true;
    group = "media";
    settings = {
      rpc-bind-address = transmissionRpcAddr;
      rpc-port = 9091;
      rpc-whitelist = "10.200.1.*,127.0.0.1";
      rpc-whitelist-enabled = true;
      rpc-authentication-required = true;
      rpc-username = "transmission";
      # Peer port — must be forwarded on Mullvad account.
      peer-port = 51413;
      # Download locations
      download-dir = "/var/lib/transmission/Downloads";
      incomplete-dir = "/var/lib/transmission/.incomplete";
      incomplete-dir-enabled = true;
    };
    # RPC password injected at runtime from sops-generated JSON credentials.
    credentialsFile = "/run/transmission/credentials.json";
  };

  # Run Transmission inside the vpn namespace.
  systemd.services.transmission = {
    after = ["vpn-namespace.service"];
    requires = ["vpn-namespace.service"];
    serviceConfig.NetworkNamespacePath = "/var/run/netns/vpn";
  };

  # ── Sonarr (TV shows) ─────────────────────────────────────────────────
  services.sonarr = {
    enable = true;
    group = "media";
  };

  # ── Radarr (Movies) ───────────────────────────────────────────────────
  services.radarr = {
    enable = true;
    group = "media";
  };

  # ── Lidarr (Music) ────────────────────────────────────────────────────
  services.lidarr = {
    enable = true;
    group = "media";
  };

  # ── Prowlarr (Indexer manager) ─────────────────────────────────────────
  # Uses DynamicUser — can't set group directly. Indexer-only, no media dir access needed.
  services.prowlarr.enable = true;

  # ── Bazarr (Subtitles) ────────────────────────────────────────────────
  services.bazarr = {
    enable = true;
    group = "media";
  };

  # ── Caddy vhosts ──────────────────────────────────────────────────────
  services.caddy.virtualHosts = {
    "sonarr.${hostname}.local".extraConfig = ''
      tls internal
      reverse_proxy 127.0.0.1:8989
      import security-headers
    '';
    "radarr.${hostname}.local".extraConfig = ''
      tls internal
      reverse_proxy 127.0.0.1:7878
      import security-headers
    '';
    "lidarr.${hostname}.local".extraConfig = ''
      tls internal
      reverse_proxy 127.0.0.1:8686
      import security-headers
    '';
    "prowlarr.${hostname}.local".extraConfig = ''
      tls internal
      reverse_proxy 127.0.0.1:9696
      import security-headers
    '';
    "bazarr.${hostname}.local".extraConfig = ''
      tls internal
      reverse_proxy 127.0.0.1:6767
      import security-headers
    '';
    # Transmission web UI — proxied through veth to the vpn namespace.
    "transmission.${hostname}.local".extraConfig = ''
      tls internal
      reverse_proxy ${transmissionRpcAddr}:9091
      import security-headers
    '';
  };

  # ── Local DNS ──────────────────────────────────────────────────────────
  networking.hosts."127.0.0.1" = [
    "sonarr.${hostname}.local"
    "radarr.${hostname}.local"
    "lidarr.${hostname}.local"
    "prowlarr.${hostname}.local"
    "bazarr.${hostname}.local"
    "transmission.${hostname}.local"
  ];

  # ── Systemd hardening for *arr services ────────────────────────────────
  # Media library dirs need to be accessible to *arr services.
  systemd.services.sonarr.serviceConfig.ReadWritePaths = mediaLibraryDirs;
  systemd.services.radarr.serviceConfig.ReadWritePaths = mediaLibraryDirs;
  systemd.services.lidarr.serviceConfig.ReadWritePaths = mediaLibraryDirs;
  systemd.services.bazarr.serviceConfig.ReadWritePaths = mediaLibraryDirs;
}
