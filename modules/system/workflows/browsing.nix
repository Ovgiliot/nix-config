# Browsing workflow — Chromium, qutebrowser, web apps.
# Requires desktop (imports it as a dependency).
{...}: {
  imports = [../desktop];

  programs.chromium.enable = true;
  nixpkgs.config.chromium.enableWideVine = true;

  home-manager.users.ethel.imports = [
    ../../home/workflows/browsing.nix
  ];
}
