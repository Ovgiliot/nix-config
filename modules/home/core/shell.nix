{...}: let
  # Defined once to keep fish and bash in sync.
  commonAliases = {
    ll = "ls -la";
    ".." = "cd ..";
    # Delete profile generations older than 7 days (user + system), then GC.
    clean-nix = "nix-collect-garbage --delete-older-than 7d && sudo nix-collect-garbage --delete-older-than 7d";
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
