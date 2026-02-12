{ config, pkgs, lib, ... }:

{
  boot.kernelModules = [ "uinput" ];
  hardware.uinput.enable = true;
  # Ensure launchers see Home Manager desktop entries in the session
  environment.sessionVariables = {
    XDG_DATA_DIRS = lib.mkForce [
      "/etc/profiles/per-user/ovg/share"
      "/run/current-system/sw/share"
      "/home/ovg/.local/share"
    ];
  };

  # XDG desktop portal for Wayland file pickers (e.g., Obsidian/Electron)
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-wlr ];
    config = {
      common = {
        default = [ "gtk" "wlr" ];
      };
    };
  };

  # Uinput setup for Kanata
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';

  users.groups.uinput = { };

  # User accounts
  users.users.ovg = {
    isNormalUser = true;
    description = "ovg";
    extraGroups = [ "networkmanager" "wheel" "input" "uinput" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Enable the Kanata service
  services.kanata = {
    enable = true;
    keyboards = {
      default = {
        configFile = ../../home/ovg/kanata.kbd;
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data were taken. Don't change this after initial install!
  system.stateVersion = "25.11";
}