# Communication workflow — WhatsApp, Discord, Telegram.
# Requires desktop and browsing (imports them as dependencies).
{...}: {
  imports = [
    ../desktop
    ./browsing.nix
  ];

  home-manager.users.ethel.imports = [
    ../../home/workflows/communication.nix
  ];
}
