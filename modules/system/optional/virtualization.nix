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

  # virt-viewer: lightweight SPICE/VNC client (provides remote-viewer).
  # Used by the windows-vm launcher script instead of opening full virt-manager.
  environment.systemPackages = [pkgs.virt-viewer];

  # virt-manager stores its settings via dconf; without this it fails silently
  # on first launch or loses configuration between sessions.
  programs.dconf.enable = true;

  # Allow VM traffic through the host firewall without opening individual ports.
  networking.firewall.trustedInterfaces = ["virbr0"];

  # libvirt's built-in NAT relies on iptables, which is silently ignored when the
  # host uses nftables. Provide an explicit nftables masquerade rule so VMs on the
  # default network (192.168.122.0/24) can reach the internet via the host.
  networking.nftables.tables.libvirt-nat = {
    family = "ip";
    content = ''
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        ip saddr 192.168.122.0/24 masquerade
      }
    '';
  };

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
