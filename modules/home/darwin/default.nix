{
  pkgs,
  dotfilesDir,
  ...
}: {
  # macOS home directory (standard location differs from Linux /home/<name>).
  home.homeDirectory = "/Users/ovg";

  # Terminal emulator — Ghostty is cross-platform.
  xdg.configFile."ghostty/config".source = dotfilesDir + "/ghostty/config";
  xdg.configFile."ghostty/shaders".source = dotfilesDir + "/ghostty/shaders";

  # Kanata keyboard remapping config link.
  # NOTE: kanata on macOS requires the Karabiner-Elements virtual HID driver
  # as a one-time manual setup. The install script prints instructions.
  # See: https://github.com/jtroo/kanata/blob/main/docs/macos.md
  xdg.configFile."kanata/kanata.kbd".source = dotfilesDir + "/kanata.kbd";

  home.packages = with pkgs; [
    # Keyboard remapping (manual driver setup required — see comment above).
    kanata

    # General utilities available on macOS.
    bitwarden-cli
    pandoc
  ];
}
