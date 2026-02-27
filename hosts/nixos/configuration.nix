{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [];

  # Default Shell
  programs.fish.enable = true;

  # User Configuration
  users.users.ovg = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "ovg";
    extraGroups = ["networkmanager" "wheel" "input" "uinput" "video"];

    # We keep system-level packages minimal.
    # Most user applications are managed via Home Manager in home/ovg/default.nix
    packages = with pkgs; [];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data were taken.
  system.stateVersion = "25.11";
}
