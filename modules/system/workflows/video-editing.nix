# Video Editing workflow — NLE and color grading.
# Requires desktop (imports it as a dependency).
{...}: {
  imports = [../desktop];

  home-manager.users.ethel.imports = [
    ../../home/workflows/video-editing.nix
  ];
}
