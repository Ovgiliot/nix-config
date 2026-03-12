# Laptop infrastructure (ThinkPad) — kernel, power management, services.
# Imports desktop as a dependency (which imports core).
{...}: {
  imports = [
    ../desktop
    ./boot.nix
    ./power.nix
    ./services.nix
  ];
}
