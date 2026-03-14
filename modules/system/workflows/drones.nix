# Drones workflow — FPV/RC configuration tools.
# Requires desktop and development (imports them as dependencies).
{...}: {
  imports = [
    ../desktop
    ./development.nix
  ];

  # TODO: joystick support (boot.kernelModules, udev rules)

  home-manager.users.ethel.imports = [
    ../../home/workflows/drones.nix
  ];
}
