{dotfilesDir, ...}: {
  xdg.configFile."wofi/config".source = dotfilesDir + "/wofi/config";
  # wofi/style.css is managed by matugen (update-colors writes it directly).
  # Bootstrap seed is provided by matugen.nix activation.
}
