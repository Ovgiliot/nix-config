# Drones workflow — FPV/RC configuration tools.
# Requires desktop (imports it as a dependency).
{...}: {
  imports = [../desktop];

  # TODO: joystick support (boot.kernelModules, udev rules)

  home-manager.users.ethel.imports = [
    ../../home/workflows/drones.nix
  ];
}
