{ config, pkgs, lib, ... }:

{
  imports = [ ];

  programs.fish.enable = true;

  # User accounts
  users.users.ovg = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "ovg";
    extraGroups = [ "networkmanager" "wheel" "input" "uinput" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data were taken. Don't change this after initial install!
  system.stateVersion = "25.11";
}