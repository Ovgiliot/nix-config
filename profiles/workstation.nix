# Workstation profile
# Full desktop (Niri/Wayland) + gaming stack. No laptop-specific power management.
{...}: {
  imports = [
    ../modules/system/desktop
    ../modules/system/optional/gaming.nix
    ../modules/system/optional/virtualization.nix
  ];

  home-manager.users.ethel.imports = [
    ../modules/home/core
    ../modules/home/desktop
  ];
}
