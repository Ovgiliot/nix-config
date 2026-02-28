{pkgs, ...}: {
  home.packages = with pkgs; [
    # Fonts
    nerd-fonts.jetbrains-mono

    # CLI / TUI Essentials
    opencode
    jq
    ripgrep
    fd
    btop
    lazygit
    ranger
    ueberzugpp
    w3m
    bat

    # --- Development Stack ---
    gnumake
    gcc
    cmake
    automake
    autoconf
    libtool
    gdb
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
  ];
}
