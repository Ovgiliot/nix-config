# ThinkPad host — uses the laptop profile.
# Machine-specific values: hostname, LUKS UUID, user account.
{inputs}: let
  dotfilesDir = ../../home/ethel;
in {
  system = "x86_64-linux";

  specialArgs = {
    inherit inputs dotfilesDir;
    # LUKS UUID for the swap/hibernate partition.
    # Used in modules/system/laptop/boot.nix to add the initrd LUKS entry.
    swapLuksUuid = "9de9918d-99aa-4f0d-8a35-22af09cf8049";
    # Full device path used by power.nix for boot.resumeDevice and resume= param.
    # Encrypted swap: /dev/mapper/luks-<swapLuksUuid>
    swapDevice = "/dev/mapper/luks-9de9918d-99aa-4f0d-8a35-22af09cf8049";
    # Kanata config resolved from the flake root; avoids fragile relative paths inside modules.
    kanataConfig = dotfilesDir + "/kanata.kbd";
    # PS/2 keyboard device path for Kanata on this ThinkPad.
    kanataDevice = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
    # Intel integrated graphics: enable VA-API acceleration packages.
    videoAcceleration = "intel";
    # Primary user for greetd autologin (display.nix).
    primaryUser = "ethel";
  };

  modules = [
    ../../profiles/laptop.nix
    ./hardware.nix
    ({pkgs, ...}: {
      networking.hostName = "nixos";

      # Fish must be enabled at the system level to be a valid login shell.
      programs.fish.enable = true;

      users.users.ethel = {
        isNormalUser = true;
        shell = pkgs.fish;
        description = "ethel";
        extraGroups = ["networkmanager" "wheel" "input" "uinput" "video" "libvirtd"];
      };

      system.stateVersion = "25.11";

      # Home Manager user identity for this host.
      home-manager.users.ethel = {
        home.username = "ethel";
        home.homeDirectory = "/home/ethel";
        home.stateVersion = "25.11";
      };
    })
  ];
}
