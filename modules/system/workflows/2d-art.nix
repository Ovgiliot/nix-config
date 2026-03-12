# 2D Art workflow — digital drawing/painting.
# Requires desktop (imports it as a dependency).
{...}: {
  imports = [../desktop];

  # TODO: Wacom tablet support (hardware.opentabletdriver)

  home-manager.users.ethel.imports = [
    ../../home/workflows/2d-art.nix
  ];
}
