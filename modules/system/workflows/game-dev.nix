# Game Development workflow — engines and toolchains.
# Requires both desktop and development.
{...}: {
  imports = [
    ../desktop
    ./development.nix
  ];

  home-manager.users.ethel.imports = [
    ../../home/workflows/game-dev.nix
  ];
}
