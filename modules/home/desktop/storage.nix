# Removable media automounting — udiskie (lightweight udisks2 frontend).
# Requires services.udisks2 on the system side (system/desktop/storage.nix).
{...}: {
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };
}
