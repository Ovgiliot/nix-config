# Workstation profile
# Full desktop (Niri/Wayland) + gaming stack. No laptop-specific power management.
# Desktop and core home modules are auto-imported by the system infrastructure.
{...}: {
  imports = [
    ../modules/system/desktop
    ../modules/system/workflows/gaming.nix
    ../modules/system/workflows/virtualization.nix
    ../modules/system/workflows/development.nix
    ../modules/system/workflows/browsing.nix
    ../modules/system/workflows/communication.nix
    ../modules/system/workflows/music.nix
    ../modules/system/workflows/notetaking.nix
  ];
}
