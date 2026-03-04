{
  pkgs,
  lib,
  palette,
  ...
}: let
  # GTK CSS uses the palette values as-is (with leading #).
  gtkCss = ''
    @define-color window_bg_color ${palette.bg};
    @define-color window_fg_color ${palette.fg};
    @define-color headerbar_bg_color ${palette.header_bg};
    @define-color headerbar_fg_color ${palette.fg};
    @define-color card_bg_color ${palette.card_bg};
    @define-color accent_bg_color ${palette.accent};
    @define-color accent_fg_color ${palette.accent_fg};
  '';

  # swaylock settings expect hex values without the leading #.
  hex = color: lib.removePrefix "#" color;
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
      color = hex palette.bg;
      font = "FiraMono Nerd Font";
      font-size = 16;
      indicator-radius = 80;
      indicator-thickness = 8;
      line-color = hex palette.bg;
      ring-color = hex palette.accent;
      inside-color = hex palette.card_bg;
      key-hl-color = hex palette.accent;
      separator-color = "00000000";
      text-color = hex palette.fg;
      bs-hl-color = "ff3333";
      ring-wrong-color = "ff3333";
      text-wrong-color = "ff3333";
      inside-wrong-color = hex palette.card_bg;
      line-wrong-color = "ff3333";
      inside-clear-color = hex palette.card_bg;
      text-clear-color = hex palette.fg;
      ring-clear-color = hex palette.accent;
      line-clear-color = hex palette.bg;
      show-failed-attempts = true;
    };
  };
}
