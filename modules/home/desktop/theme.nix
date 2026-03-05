{pkgs, ...}: {
  gtk = {
    enable = true;
    font = {
      name = "FiraMono Nerd Font";
      size = 11;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    # GTK4 colors are written by matugen to ~/.cache/matugen/gtk4-colors.css
    # (because HM owns ~/.config/gtk-4.0/gtk.css as a read-only Nix store symlink).
    # This import makes HM's generated gtk.css pull in the matugen output at runtime.
    gtk4.extraCss = ''
      @import url("/home/ovg/.cache/matugen/gtk4-colors.css");
    '';
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # swaylock binary — config is written by matugen (see matugen.nix).
  # PAM integration lives in modules/system/desktop/display.nix.
  home.packages = [pkgs.swaylock];
}
