# Laptop profile (ThinkPad)
# Full desktop (Niri/Wayland) + ThinkPad-specific power management.
{...}: {
  imports = [
    ../modules/system/laptop
    ../modules/system/optional/virtualization.nix
  ];

  home-manager.users.ethel.imports = [
    ../modules/home/core
    ../modules/home/desktop
    ../modules/home/laptop
  ];
}
