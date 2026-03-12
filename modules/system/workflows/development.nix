# Development workflow — system entry point.
# Pure home-manager workflow: no system-level config needed.
# Imports core as a dependency (works on servers and desktops).
{...}: {
  imports = [../core];

  home-manager.users.ethel.imports = [
    ../../home/workflows/development.nix
  ];
}
