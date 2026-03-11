{
  pkgs,
  kanataConfig,
  kanataDevice,
  ...
}: {
  # Kernel modules for uinput (needed for Kanata)
  boot.kernelModules = ["uinput"];
  hardware.uinput.enable = true;

  # Uinput setup for Kanata
  # Touchpad (Synaptics TM3276-022): start inhibited (trackpoint preferred) and
  # make the sysfs inhibited attribute user-writable so the toggle-touchpad
  # script can flip it without sudo.
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Synaptics TM3276-022", ATTR{inhibited}="1", RUN+="${pkgs.coreutils}/bin/chmod 0666 %S%p/inhibited"
  '';

  users.groups.uinput = {};

  # Enable the Kanata service
  services.kanata = {
    enable = true;
    keyboards = {
      default = {
        # Path is passed from the host's specialArgs to avoid fragile ../../ navigation.
        configFile = kanataConfig;
        # Device path is host-specific; passed via kanataDevice specialArg.
        devices = [kanataDevice];
      };
    };
  };

  # Keyboard layout (X11/Wayland)
  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    options = "grp:ctrl_space_toggle";
  };
}
