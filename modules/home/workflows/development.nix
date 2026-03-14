# Development home workflow — dev tools, LSPs, formatters, nvim dev plugins.
{
  pkgs,
  lib,
  config,
  dotfilesDir,
  ...
}: let
  homeLib = import ../lib.nix {inherit lib pkgs config;};
  inherit (homeLib) stripShebang;

  # Opens opencode in the dotfiles repo directory.
  opencodeDotfiles = pkgs.writeShellApplication {
    name = "opencode-dotfiles";
    runtimeInputs = [pkgs.opencode];
    text = ''
      cd "$HOME/dotfiles/nix-config"
      exec opencode
    '';
  };
in {
  home.packages = with pkgs;
    [
      # Build toolchain
      gnumake
      gcc
      cmake
      automake
      autoconf
      libtool
      sqlite

      # Language Servers & Formatters
      lua-language-server
      stylua
      nixd
      alejandra
      clang-tools
      bash-language-server
      shfmt
      shellcheck
      nodejs # Required for many LSPs

      # Hardware & Firmware
      python3
      dfu-util

      # Graphics Development
      glslang

      # .NET Development
      omnisharp-roslyn
      netcoredbg

      # AI / Workflow
      opencode
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # gdb: requires code-signing entitlements on macOS not provided by nixpkgs.
      # Use lldb (bundled with Xcode CLT) on macOS instead.
      gdb
    ]
    ++ [
      opencodeDotfiles
    ];

  # Dev-specific Neovim plugins (merged with core plugins by the module system).
  programs.neovim.plugins = with pkgs.vimPlugins; [
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

    # Formatting & Linting
    conform-nvim
    nvim-lint

    # Debugging
    nvim-dap
    nvim-dap-ui
    nvim-nio

    # AI
    copilot-vim
    opencode-nvim

    # Git integration
    neogit
    diffview-nvim

    # Dev-specific treesitter parsers
    (nvim-treesitter.withPlugins (p: [
      p.c
      p.cpp
      p.lua
      p.c_sharp
      p.glsl
      p.hlsl
    ]))
  ];
}
