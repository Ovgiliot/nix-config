{
  pkgs,
  dotfilesDir,
  ...
}: {
  home.packages = [pkgs.qutebrowser];
  home.sessionVariables.BROWSER = "qutebrowser";
  xdg.configFile."qutebrowser/config.py".source = dotfilesDir + "/qutebrowser/config.py";

  # Default browser — MIME associations managed declaratively.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/http" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/https" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/chrome" = "org.qutebrowser.qutebrowser.desktop";
      "application/xhtml+xml" = "org.qutebrowser.qutebrowser.desktop";
      "application/x-extension-htm" = "org.qutebrowser.qutebrowser.desktop";
      "application/x-extension-html" = "org.qutebrowser.qutebrowser.desktop";
      "application/x-extension-shtml" = "org.qutebrowser.qutebrowser.desktop";
      "application/x-extension-xhtml" = "org.qutebrowser.qutebrowser.desktop";
      "application/x-extension-xht" = "org.qutebrowser.qutebrowser.desktop";
    };
  };
}
