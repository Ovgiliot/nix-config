{
  config,
  pkgs,
  lib,
  kanataConfig,
  ...
}: {
  # Kernel modules for uinput (needed for Kanata)
  boot.kernelModules = ["uinput"];
  hardware.uinput.enable = true;

  # Uinput setup for Kanata
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';

  users.groups.uinput = {};

  # Enable the Kanata service
  services.kanata = {
    enable = true;
    keyboards = {
      default = {
        # Path is passed from flake.nix specialArgs to avoid fragile ../../ navigation.
        configFile = kanataConfig;
        devices = ["/dev/input/by-path/platform-i8042-serio-0-event-kbd"];
      };
    };
  };

  # Keyboard layout (X11/Wayland)
  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    options = "grp:ctrl_space_toggle,caps:escape";
  };
}
