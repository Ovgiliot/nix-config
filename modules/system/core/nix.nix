{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Enable experimental Nix features for flakes
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
  };

  # Automatic Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Pin the system's nixpkgs registry entry to the exact flake input.
  # This means `nix shell nixpkgs#foo` reuses the already-fetched nixpkgs
  # instead of downloading a separate copy, and keeps versions consistent.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # Keep the legacy NIX_PATH in sync so tools that use <nixpkgs> still work.
  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
}
