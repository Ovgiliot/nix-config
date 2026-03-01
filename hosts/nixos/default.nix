# ThinkPad host — uses the laptop profile.
# Machine-specific values: hostname, LUKS UUID, user account.
{inputs}: let
  dotfilesDir = ../../home/ovg;
in {
  system = "x86_64-linux";

  specialArgs = {
    inherit inputs dotfilesDir;
    # LUKS UUID for the swap/hibernate partition.
    # Used in modules/system/laptop/boot.nix and laptop/power.nix.
    swapLuksUuid = "9de9918d-99aa-4f0d-8a35-22af09cf8049";
    # Kanata config resolved from the flake root; avoids fragile relative paths inside modules.
    kanataConfig = dotfilesDir + "/kanata.kbd";
    # PS/2 keyboard device path for Kanata on this ThinkPad.
    kanataDevice = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
    # Intel integrated graphics: enable VA-API acceleration packages.
    videoAcceleration = "intel";
  };

  modules = [
    ../../profiles/laptop.nix
    ./hardware.nix
    ({pkgs, ...}: {
      networking.hostName = "nixos";

      # Fish must be enabled at the system level to be a valid login shell.
      programs.fish.enable = true;

      users.users.ovg = {
        isNormalUser = true;
        shell = pkgs.fish;
        description = "ovg";
        extraGroups = ["networkmanager" "wheel" "input" "uinput" "video"];
      };

      system.stateVersion = "25.11";

      # Home Manager user identity for this host.
      home-manager.users.ovg = {
        home.username = "ovg";
        home.homeDirectory = "/home/ovg";
        home.stateVersion = "25.11";
      };
    })
  ];
}
