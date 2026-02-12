{ config, pkgs, inputs, ... }:

{
    imports = [
        ./vscode-admin.nix
            ./web-apps.nix
    ];

# Home Manager needs a bit of information about you and the paths it should manage
    home.username = "ovg";
    home.homeDirectory = "/home/ovg";

# This value determines the Home Manager release that your configuration is
# compatible with. This helps avoid breakage when a new Home Manager release
# introduces backwards incompatible changes.
    home.stateVersion = "25.11";

# Let Home Manager install and manage itself
    programs.home-manager.enable = true;

# Ensure XDG base dirs and data dirs are set for desktop entry discovery
    xdg.enable = true;

# Ensure launchers see Home Manager desktop entries
    home.sessionVariables = {
        XDG_DATA_DIRS = "${config.home.profileDirectory}/share:/etc/profiles/per-user/ovg/share:/run/current-system/sw/share:/home/ovg/.local/share";
    };

# User packages - GUI applications and development tools
    home.packages = with pkgs; [
# enviroment packages
        xwayland-satellite  # For X11 app support in niri
            inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default  # Noctalia shell package for the current system
            inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
            wofi
            mako
            wl-clipboard
            grim
            slurp
            gemini-cli
            jq
            kanata # For homerow mods
# GUI applications
            playerctl # Required for media key bindings in Niri
            bitwarden-desktop
            obsidian
            thunar
            ghostty
    ];

# Git configuration (uncomment and customize as needed)
    programs.git = {
        enable = true;
        userName = "Ovgiliot";
        userEmail = "ovgiliot@gmail.com";
    };

# VS Code configuration
    programs.vscode = {
        enable = true;
# extensions = with pkgs.vscode-extensions; [
#   # Add your favorite extensions here
# ];
    };

# Neovim (user config)
    programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
    };

# Shell configuration
    programs.bash = {
        enable = true;
        shellAliases = {
            ll = "ls -la";
            ".." = "cd ..";
            clean-nix = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +10 && sudo nix-collect-garbage -d";
        };
    };

# Niri configuration (user config file)
    xdg.configFile."niri".source = ./niri;

# Neovim configuration
    xdg.configFile."nvim/init.lua".source = ../../modules/system/nvim/init.lua;
    xdg.configFile."nvim/lua".source = ../../modules/system/nvim/lua;

# Kanata configuration
    xdg.configFile."kanata/kanata.kbd".source = ./kanata.kbd;

# Ghostty configuration

    xdg.configFile."ghostty/config".source = ./ghostty/config;

    xdg.configFile."ghostty/shaders".source = ./ghostty/shaders;

}


