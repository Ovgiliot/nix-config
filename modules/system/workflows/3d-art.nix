# 3D Art workflow — modeling, sculpting, VFX.
# Requires desktop (imports it as a dependency).
{...}: {
  imports = [../desktop];

  # TODO: GPU driver optimization for compute workloads

  home-manager.users.ethel.imports = [
    ../../home/workflows/3d-art.nix
  ];
}
