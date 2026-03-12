# Virtualization home workflow — VM launcher script and .desktop entry.
{
  config,
  pkgs,
  lib,
  dotfilesDir,
  ...
}: let
  stripShebang = text: lib.strings.removePrefix "#!/usr/bin/env bash\n" text;

  windowsVm = pkgs.writeShellApplication {
    name = "windows-vm";
    runtimeInputs = with pkgs; [libvirt virt-viewer libnotify coreutils gnugrep];
    text = stripShebang (builtins.readFile (dotfilesDir + "/scripts/windows-vm.sh"));
  };
in {
  home.packages = [windowsVm];

  # .desktop entry so the VM shows up in wofi's drun launcher.
  home.file."${config.xdg.dataHome}/applications/windows-vm.desktop".text = ''
    [Desktop Entry]
    Version=1.5
    Type=Application
    Name=Windows VM
    Comment=Start or connect to the Windows 11 KVM virtual machine
    Exec=windows-vm
    Terminal=false
    Categories=System;Emulator;
    Icon=virt-manager
  '';
}
