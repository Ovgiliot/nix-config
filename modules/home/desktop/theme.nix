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
