{...}: {
  # Override home directory for macOS (standard location is /Users/<name>)
  home.homeDirectory = "/Users/ovg";

  # macOS-specific packages or settings go here as needed.
  # System-level macOS preferences are managed in the darwin profile via nix-darwin.
}
