# Core system infrastructure — every NixOS machine imports this.
# Boot, nix settings, locale, networking, security, home-manager base.
{
  inputs,
  dotfilesDir,
  pkgs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./boot.nix
    ./nix.nix
    ./locale.nix
    ./networking.nix
    ./security.nix
  ];

  # Allow pre-built (non-nixpkgs) binaries to find system libraries.
  # Required for apps like MilELRS Configurator that ship as pre-compiled
  # Flutter/GTK bundles.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    gtk3
    gdk-pixbuf
    glib
    cairo
    pango
    harfbuzz
    atk
    libepoxy
    fontconfig
    zlib
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    stdenv.cc.cc.lib # libstdc++
  ];

  # Weekly GC via systemd timer. Set here (not nix.nix) because nix.nix is
  # shared with darwin, which uses launchd intervals instead.
  nix.gc.dates = "weekly";

  # Home Manager base configuration — shared across all NixOS profiles.
  # Individual profiles/workflows add to users.ethel.imports; the module
  # system merges the lists.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {inherit inputs dotfilesDir;};
    users.ethel.imports = [
      ../../home/core
    ];
  };
}
