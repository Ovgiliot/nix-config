{...}: let
  # Defined once to keep fish and bash in sync.
  commonAliases = {
    ll = "ls -la";
    ".." = "cd ..";
    # Delete profile generations older than 14 days (user + system), then GC.
    # Matches the 14d threshold in nix.nix gc.maxAge.
    clean-nix = "nix-collect-garbage --delete-older-than 14d && sudo nix-collect-garbage --delete-older-than 14d";
  };
in {
  programs.fish = {
    enable = true;
    shellAliases = commonAliases;
  };

  programs.bash = {
    enable = true;
    shellAliases = commonAliases;
  };
}
