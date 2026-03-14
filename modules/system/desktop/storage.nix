# Removable media — udisks2 for D-Bus storage management.
# Paired with udiskie in home/desktop/storage.nix for automounting.
{...}: {
  services.udisks2.enable = true;
}
