{...}: {
  # QEMU/KVM virtualization with virt-manager GUI.
  # Primary use case: Windows VM for hardware flasher tools that need USB passthrough.
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      # UEFI firmware for VMs (required for Windows 11, recommended for Windows 10).
      ovmf.enable = true;
      # Software TPM — Windows 11 requires a TPM 2.0 device.
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
}
