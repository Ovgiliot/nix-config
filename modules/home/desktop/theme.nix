{pkgs, ...}: let
  # --- Appearance Colors ---
  # Defined once; flows through GTK CSS, swaylock, and any other themed component.
  bg = "#131314";
  fg = "#e6edf3";
  accent = "#2f81f7";
  accent_fg = "#ffffff";
  header_bg = "#1a1a1b";
  card_bg = "#1d1d1e";

  # --- Shared GTK3 / GTK4 CSS Theme Variables ---
  gtkCss = ''
    @define-color window_bg_color ${bg};
    @define-color window_fg_color ${fg};
    @define-color headerbar_bg_color ${header_bg};
    @define-color headerbar_fg_color ${fg};
    @define-color card_bg_color ${card_bg};
    @define-color accent_bg_color ${accent};
    @define-color accent_fg_color ${accent_fg};
  '';
in {
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
    gtk3.extraCss = gtkCss;
    gtk4.extraCss = gtkCss;
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

  # Screen Locker (themed to match the colour palette)
  # The config here generates ~/.config/swaylock/config.
  # swayidle in niri/config.kdl invokes 'swaylock -f'.
  programs.swaylock = {
    enable = true;
    settings = {
      color = "131314";
      font = "FiraMono Nerd Font";
      font-size = 16;
      indicator-radius = 80;
      indicator-thickness = 8;
      line-color = "131314";
      ring-color = "2f81f7";
      inside-color = "1d1d1e";
      key-hl-color = "2f81f7";
      separator-color = "00000000";
      text-color = "e6edf3";
      bs-hl-color = "ff3333";
      ring-wrong-color = "ff3333";
      text-wrong-color = "ff3333";
      inside-wrong-color = "1d1d1e";
      line-wrong-color = "ff3333";
      inside-clear-color = "1d1d1e";
      text-clear-color = "e6edf3";
      ring-clear-color = "2f81f7";
      line-clear-color = "131314";
      show-failed-attempts = true;
    };
  };
}
