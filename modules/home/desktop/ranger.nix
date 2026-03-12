# Ranger preview dependencies — desktop-only (headless servers don't need these).
{pkgs, ...}: {
  home.packages = with pkgs; [
    ffmpeg
    ffmpegthumbnailer
    atool
    p7zip
    unzip
    highlight
    exiftool
    librsvg
    ueberzugpp
  ];
}
