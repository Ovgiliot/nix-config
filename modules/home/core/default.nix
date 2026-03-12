{
  lib,
  dotfilesDir,
  ...
}: {
  imports = [
    ./shell.nix
    ./packages.nix
    ./neovim.nix
    ./keymap.nix
    ./scripts.nix
  ];

  # User identity — defaults for all profiles.
  # Darwin overrides homeDirectory; hosts can override stateVersion.
  # mkDefault allows higher-priority overrides without conflict.
  home.username = lib.mkDefault "ethel";
  home.homeDirectory = lib.mkDefault "/home/ethel";
  home.stateVersion = lib.mkDefault "25.11";

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

  # XDG links for core tools — nvim is handled by keymap.nix (hybrid runCommand).
  xdg.configFile."ranger/rc.conf".source = dotfilesDir + "/ranger/rc.conf";
  xdg.configFile."ranger/rifle.conf".source = dotfilesDir + "/ranger/rifle.conf";
  xdg.configFile."ranger/scope.sh".source = dotfilesDir + "/ranger/scope.sh";

  # Global OpenCode agent: 'talk' — web-search-only agent available in any project.
  xdg.configFile."opencode/agents/talk.md".source = dotfilesDir + "/opencode/agents/talk.md";
}
