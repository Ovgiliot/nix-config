{pkgs, ...}: {
  # Primary Editor
  # All plugins declared here so Nix manages the full plugin set — single source of truth.
  # Treesitter parsers must come from Nix on NixOS (compiled .so files; :TSInstall cannot
  # compile at runtime on an immutable filesystem).
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      # Treesitter + parsers
      (nvim-treesitter.withPlugins (p: [
        p.c
        p.cpp
        p.lua
        p.vim
        p.vimdoc
        p.query
        p.markdown
        p.markdown_inline
        p.nix
        p.bash
        p.fish
        p.c_sharp
        p.glsl
        p.hlsl
        # org is not available in nixpkgs grammarPlugins; orgmode ships its own parser
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

      # Org Mode
      orgmode
      org-roam-nvim
      sqlite-lua
      headlines-nvim

      # Git
      neogit
      diffview-nvim

      # AI
      copilot-vim
      snacks-nvim
      opencode-nvim

      # LSP
      nvim-lspconfig

      # Completion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      cmp_luasnip
      luasnip
      friendly-snippets

      # Formatting
      conform-nvim

      # Linting
      nvim-lint

      # Debugging
      nvim-dap
      nvim-dap-ui
      nvim-nio

      # Autosave
      auto-save-nvim
    ];
  };
}
