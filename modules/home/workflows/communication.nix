# Communication home workflow — WhatsApp (web app), Discord, Telegram.
{
  config,
  pkgs,
  lib,
  ...
}: let
  homeLib = import ../lib.nix {inherit lib pkgs config;};
  inherit (homeLib) mkDesktopFile;

  # ── Web apps ──────────────────────────────────────────────────────────
  webApps = [
    {
      name = "WhatsApp";
      url = "https://web.whatsapp.com";
      icon = "web-browser";
    }
  ];
in {
  home.packages = [
    pkgs.discord
    pkgs.telegram-desktop
  ];

  # Declarative web apps (Chromium app mode).
  home.file = builtins.listToAttrs (map mkDesktopFile webApps);
}
