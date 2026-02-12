# This is a legacy file maintained for backwards compatibility.
# The actual configuration is now managed through flake.nix and modular files.
#
# To rebuild your system, use:
#   sudo nixos-rebuild switch --flake /etc/nixos#nixos
#
# Configuration structure:
#   flake.nix                 - Main flake with inputs/outputs
#   hosts/nixos/              - Host-specific configuration
#   modules/system/           - System modules (boot, networking, desktop, etc.)
#   home/ovg/                 - Home-manager user configuration

{ config, lib, pkgs, ... }:

{
  # This file is kept for compatibility but configuration is now in flake.nix
  # You can safely ignore or remove this file after migration
  imports = lib.mkDefault [ ];
}
