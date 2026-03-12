{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs;
    [
      # Fonts
      nerd-fonts.fira-mono

      # CLI / TUI Essentials
      # git: installed via programs.git in core/default.nix — do not add here.
      opencode
      jq
      ripgrep
      fd
      btop
      lazygit
      ranger
      w3m
      bat

      # --- Development Stack ---
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

      # Graphics Development
      glslang

      # .NET Development
      omnisharp-roslyn
      netcoredbg

      # Ranger Preview Dependencies
      ffmpeg
      ffmpegthumbnailer
      atool
      p7zip
      unzip
      highlight
      exiftool
      librsvg
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # ueberzugpp: image display for ranger previews via X11/Wayland.
      # Not functional on macOS (no compatible display backend).
      ueberzugpp

      # gdb: requires code-signing entitlements on macOS not provided by nixpkgs.
      # Use lldb (bundled with Xcode CLT) on macOS instead.
      gdb
    ];
}
