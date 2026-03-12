{pkgs, ...}: {
  # QEMU/KVM virtualization with virt-manager GUI.
  # Primary use case: Windows VM for hardware flasher tools that need USB passthrough.
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      # Software TPM — Windows 11 requires a TPM 2.0 device.
      # OVMF (UEFI firmware) is included by default with QEMU.
      swtpm.enable = true;
    };
  };

  # USB device passthrough via SPICE — lets the VM access host USB devices
  # (serial adapters, hardware flashers, etc.) as if they were physically attached.
  virtualisation.spiceUSBRedirection.enable = true;

  # virt-manager: GTK GUI for creating, configuring, and running VMs.
  # Handles USB passthrough configuration, display, snapshots, etc.
  programs.virt-manager.enable = true;

  # virt-manager stores its settings via dconf; without this it fails silently
  # on first launch or loses configuration between sessions.
  programs.dconf.enable = true;

  # Workaround: libvirt 12.1.0 ships virt-secret-init-encryption.service with a
  # hardcoded /usr/bin/sh that doesn't exist on NixOS. Patch ExecStart to use an
  # absolute Nix store path instead.
  # TODO: remove once upstream ships a fixed service file (check after libvirt >12.1.0).
  systemd.services.virt-secret-init-encryption = {
    serviceConfig.ExecStart = let
      script = pkgs.writeShellScript "virt-secret-init-encryption" ''
        umask 0077
        mkdir -p /var/lib/libvirt/secrets
        dd if=/dev/random status=none bs=32 count=1 \
          | ${pkgs.systemd}/bin/systemd-creds encrypt \
              --name=secrets-encryption-key \
              - /var/lib/libvirt/secrets/secrets-encryption-key
      '';
    in ["" "${script}"];
  };
}
