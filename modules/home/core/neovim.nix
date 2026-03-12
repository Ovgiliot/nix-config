{pkgs, ...}: {
  # Primary Editor
  # Base plugins declared here; workflow modules add their own plugins via
  # programs.neovim.plugins (NixOS module system merges lists).
  # Treesitter parsers must come from Nix on NixOS (compiled .so files; :TSInstall cannot
  # compile at runtime on an immutable filesystem).
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      # Treesitter + base parsers (language-specific parsers added by workflows)
      (nvim-treesitter.withPlugins (p: [
        p.vim
        p.vimdoc
        p.query
        p.markdown
        p.markdown_inline
        p.nix
        p.bash
        p.fish
      ]))

      # Theme & UI
      lualine-nvim
      nvim-web-devicons
      which-key-nvim

      # Telescope
      telescope-nvim
      plenary-nvim
      telescope-fzf-native-nvim
      telescope-ui-select-nvim

      # File Management
      ranger-nvim

      # Utilities
      snacks-nvim
      auto-save-nvim
    ];
  };
}
