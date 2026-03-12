# Note-taking home workflow — org-mode nvim plugins, pandoc.
{pkgs, ...}: {
  home.packages = [pkgs.pandoc];

  # Org-mode Neovim plugins (merged with core plugins by the module system).
  programs.neovim.plugins = with pkgs.vimPlugins; [
    orgmode
    org-roam-nvim
    sqlite-lua
    headlines-nvim
  ];
}
