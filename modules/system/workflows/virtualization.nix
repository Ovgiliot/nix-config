# Virtualization workflow — QEMU/KVM with virt-manager.
# Requires core (works on servers and desktops).
{pkgs, ...}: {
  imports = [../core];

  # QEMU/KVM virtualization with virt-manager GUI.
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      # Software TPM — Windows 11 requires a TPM 2.0 device.
      swtpm.enable = true;
    };
  };

  # USB device passthrough via SPICE.
  virtualisation.spiceUSBRedirection.enable = true;

  # virt-manager: GTK GUI for creating, configuring, and running VMs.
  programs.virt-manager.enable = true;

  # virt-viewer: lightweight SPICE/VNC client (provides remote-viewer).
  environment.systemPackages = [pkgs.virt-viewer];

  # virt-manager stores settings via dconf.
  programs.dconf.enable = true;

  # Allow VM traffic through the host firewall.
  networking.firewall.trustedInterfaces = ["virbr0"];

  # Explicit nftables masquerade rule for libvirt NAT.
  networking.nftables.tables.libvirt-nat = {
    family = "ip";
    content = ''
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        ip saddr 192.168.122.0/24 masquerade
      }
    '';
  };

  # Ensure the default NAT network starts with libvirtd.
  # libvirt defines 'default' but doesn't always autostart it on NixOS.
  systemd.services.libvirt-default-network = {
    description = "Autostart libvirt default NAT network";
    wantedBy = ["multi-user.target"];
    requires = ["libvirtd.service"];
    after = ["libvirtd.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # Mark for autostart, then start if not already active.
    script = ''
      ${pkgs.libvirt}/bin/virsh net-autostart default || true
      ${pkgs.libvirt}/bin/virsh net-start default || true
    '';
  };

  # Workaround: libvirt 12.1.0 ships virt-secret-init-encryption.service with a
  # hardcoded /usr/bin/sh that doesn't exist on NixOS.
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

  home-manager.users.ethel.imports = [
    ../../home/workflows/virtualization.nix
  ];
}
