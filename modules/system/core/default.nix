# Core system infrastructure — every NixOS machine imports this.
# Boot, nix settings, locale, networking, security.
{...}: {
  imports = [
    ./boot.nix
    ./nix.nix
    ./locale.nix
    ./networking.nix
    ./security.nix
  ];
}
