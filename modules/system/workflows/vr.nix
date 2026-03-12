# VR workflow — OpenXR runtime and headset support.
# Requires desktop and gaming.
{...}: {
  imports = [
    ../desktop
    ./gaming.nix
  ];

  # TODO: OpenXR/monado, SteamVR, headset udev rules

  home-manager.users.ethel.imports = [
    ../../home/workflows/vr.nix
  ];
}
