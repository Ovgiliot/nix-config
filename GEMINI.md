# Project Overview

This directory contains a NixOS configuration that leverages flakes and home-manager for a modular, reproducible system setup. It's designed to manage both system-wide configurations (NixOS) and user-specific configurations (Home Manager) in a consistent and declarative manner.

**Main Technologies:**
- **NixOS**: A Linux distribution built on the Nix package manager, emphasizing declarative system configuration and atomic upgrades.
- **Nix Flakes**: A new feature in Nix that provides a more reproducible and hermetic way to manage dependencies and define system configurations.
- **Home Manager**: A Nix-based tool for managing user-specific configurations and packages, ensuring dotfiles and user environments are reproducible.

**Architecture:**
The configuration is structured modularly:
- `configuration.nix`: Main system configuration (kept for compatibility with older NixOS setups).
- `flake.nix`: The main entry point for the Nix flake, defining inputs and outputs (NixOS configurations, Home Manager configurations).
- `hosts/`: Contains host-specific NixOS configurations (e.g., `nixos/configuration.nix` for a machine named 'nixos').
- `modules/system/`: Contains reusable NixOS modules for various system aspects like boot, networking, desktop environment, audio, and services.
- `home/`: Contains user-specific Home Manager configurations (e.g., `home/ovg/default.nix`, which often imports other user-specific config files like `vscode-admin.nix` or `web-apps.nix` for user 'ovg').

## Features

- **Flakes**: Reproducible builds with pinned dependencies
- **Home Manager**: User-level package and configuration management
- **Modular Structure**: Clean separation of concerns
- **KDE Plasma 6**: Full-featured desktop environment
- **Niri**: Wayland compositor as alternative session (from nixpkgs)
- **PipeWire**: Modern audio with ALSA, PulseAudio, and JACK support
- **VS Code**: With optional admin/root launcher

## Building and Running

The project uses `nixos-rebuild` with flake syntax for managing the system configuration.

### Initial Setup

```bash
cd /home/ovg/dotfiles/nix # Assuming this is the current directory
sudo nix flake update
```

### Rebuilding the System

- **Switch to new configuration:** Applies and activates the new configuration.
    ```bash
    sudo nixos-rebuild switch --flake .#nixos
    ```
- **Test configuration without switching:** Builds the configuration but doesn't activate it, useful for checking for build errors.
    ```bash
    sudo nixos-rebuild test --flake .#nixos
    ```
- **Build but don't activate:** Builds the configuration without applying it.
    ```bash
    sudo nixos-rebuild build --flake .#nixos
    ```

### Updating Dependencies

- **Update all flake inputs:**
    ```bash
    sudo nix flake update
    ```
- **Update specific input (e.g., nixpkgs):**
    ```bash
    sudo nix flake lock --update-input nixpkgs
    ```

## Development Conventions

- **Declarative Configuration**: All system and user configurations are defined declaratively using Nix expressions.
- **Modular Design**: Configurations are broken down into small, reusable modules to enhance readability and maintainability.
- **Flake-based**: Relies on Nix Flakes for reproducible dependency management.
- **Home Manager Integration**: User-level configurations are managed via Home Manager, ensuring consistency across user environments.

### Customization

- **Adding System Packages**: Modify `hosts/nixos/configuration.nix` or the relevant module under `modules/system/`.
- **Adding User Packages**: Modify `home/ovg/default.nix` to include user-specific packages and configurations.
- **Adding New Hosts**:
    1. Create a new directory under `hosts/<hostname>/`.
    2. Add `configuration.nix` and `hardware-configuration.nix` within the new host directory.
    3. Add an entry for the new host in `flake.nix` under `nixosConfigurations`.
- **Adding New Users**:
    1. Create a new directory under `home/<username>/`.
    2. Add `default.nix` with Home Manager configuration for the new user.
    3. Add the user in the host configuration and integrate the Home Manager module in `flake.nix`.