{dotfilesDir, ...}: {
  imports = [
    ./shell.nix
    ./packages.nix
    ./neovim.nix
  ];

  # User identity — common across all Linux profiles.
  # Darwin profile overrides home.homeDirectory.
  home.username = "ovg";
  home.homeDirectory = "/home/ovg";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
  xdg.enable = true;

  # Git Identity
  programs.git = {
    enable = true;
    settings.user = {
      name = "Ovgiliot";
      email = "ovgiliot@gmail.com";
    };
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  # XDG links for core tools
  xdg.configFile."nvim".source = dotfilesDir + "/nvim";
  xdg.configFile."ranger/rc.conf".source = dotfilesDir + "/ranger/rc.conf";
  xdg.configFile."ranger/rifle.conf".source = dotfilesDir + "/ranger/rifle.conf";
  xdg.configFile."ranger/scope.sh".source = dotfilesDir + "/ranger/scope.sh";

  # Global OpenCode agent: 'talk' — web-search-only agent available in any project.
  xdg.configFile."opencode/agents/talk.md".source = dotfilesDir + "/opencode/agents/talk.md";
}
