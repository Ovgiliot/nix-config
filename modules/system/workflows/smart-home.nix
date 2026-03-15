# Smart Home workflow — native Home Assistant for home automation.
# Requires services infrastructure (imports Caddy, Prometheus, fail2ban, sops).
#
# Architecture:
#   - Home Assistant runs natively (not containerized) via services.home-assistant
#   - Bound to localhost only; Caddy provides TLS-terminated access at
#     home.<hostname>.local with WebSocket support for the HA frontend
#   - HA's built-in ip_ban_enabled handles brute-force protection
#   - UI-managed automations/scenes/scripts via !include YAML files
#   - No HACS — use customComponents from nixpkgs instead
#   - No Mosquitto/MQTT by default — add when hardware requires it
#
# First boot: expect ModuleNotFoundError for auto-discovered but undeclared
# integrations. Add them to extraComponents as needed.
#
# State lives in /var/lib/hass/ — back this up. The .storage/ subdirectory
# contains device registrations, entity configs, and auth tokens.
{config, ...}: let
  hostname = config.networking.hostName;
in {
  imports = [
    ../services
  ];

  # ── Home Assistant ─────────────────────────────────────────────────────
  services.home-assistant = {
    enable = true;

    # Components to include Python dependencies for. The module auto-discovers
    # integrations from `config` keys, but explicit listing ensures deps are
    # available at first boot before discovery runs.
    extraComponents = [
      # Core / onboarding
      "default_config"
      "met"
      "radio_browser"
      "shopping_list"
      "isal" # Fast compression (recommended by NixOS wiki)

      # Network discovery
      "zeroconf"
      "ssdp"
      "dhcp"
      "usb"

      # Ecosystem
      "esphome"
      "mobile_app"
      "cast"
      "homekit"
      "homekit_controller"

      # Utility
      "backup"
      "webhook"
      "rest"
      "command_line"
      "sun"
      "energy"
    ];

    # Declarative configuration.yaml — merged with auto-discovered config.
    # UI-managed automations/scenes/scripts use !include to coexist.
    config = {
      default_config = {};

      homeassistant = {
        name = "Home";
        unit_system = "metric";
      };

      # Bind to localhost — Caddy handles external access with TLS.
      http = {
        server_host = ["127.0.0.1" "::1"];
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = ["127.0.0.1" "::1"];
        # Built-in brute-force protection.
        ip_ban_enabled = true;
        login_attempts_threshold = 5;
      };

      # UI-managed YAML files — allows creating automations/scenes/scripts
      # from the HA frontend while keeping the base config declarative.
      "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
      "script ui" = "!include scripts.yaml";
    };
  };

  # ── Ensure UI-managed YAML files exist ─────────────────────────────────
  # HA fails on first boot if !include targets don't exist.
  systemd.tmpfiles.rules = [
    "f ${config.services.home-assistant.configDir}/automations.yaml 0644 hass hass"
    "f ${config.services.home-assistant.configDir}/scenes.yaml 0644 hass hass"
    "f ${config.services.home-assistant.configDir}/scripts.yaml 0644 hass hass"
  ];

  # ── Caddy vhost ────────────────────────────────────────────────────────
  # Caddy handles TLS termination and WebSocket proxying (automatic with
  # reverse_proxy — no special config needed unlike nginx).
  services.caddy.virtualHosts."home.${hostname}.local" = {
    extraConfig = ''
      tls internal
      import security-headers
      reverse_proxy 127.0.0.1:8123
    '';
  };

  # ── Local DNS ──────────────────────────────────────────────────────────
  networking.hosts."127.0.0.1" = [
    "home.${hostname}.local"
  ];
}
