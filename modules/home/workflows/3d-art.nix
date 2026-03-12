# 3D Art home workflow — modeling, sculpting, VFX.
{pkgs, ...}: {
  home.packages = with pkgs; [
    blender
    # TODO: houdini (not in nixpkgs — requires manual packaging or overlay)
  ];
}
