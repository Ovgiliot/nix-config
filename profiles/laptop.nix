# Laptop profile (ThinkPad)
# Full desktop (Niri/Wayland) + ThinkPad-specific power management.
# Desktop, laptop, and core home modules are auto-imported by the system infrastructure.
{...}: {
  imports = [
    ../modules/system/laptop
    ../modules/system/workflows/virtualization.nix
    ../modules/system/workflows/development.nix
    ../modules/system/workflows/browsing.nix
    ../modules/system/workflows/music.nix
    ../modules/system/workflows/notetaking.nix
  ];
}
