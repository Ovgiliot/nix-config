# Headless server profile
# Minimal NixOS: core nix/locale/networking + full CLI home config (shell, neovim, tools).
# No display server, audio, or desktop environment.
{...}: {
  imports = [
    ../modules/system/server
    ../modules/system/workflows/development.nix
  ];
}
