# Project Overview

This directory contains a NixOS configuration that leverages **Flakes** and **Home Manager** for a modular, reproducible system setup. It is tailored for a high-performance, modern Linux desktop experience, featuring **Niri** (scrollable-tiling Wayland compositor) and **KDE Plasma 6**.

**Core Technologies:**
- **NixOS**: Declarative system configuration.
- **Nix Flakes**: Reproducible dependency management (`flake.nix`).
- **Home Manager**: User-specific configuration management.

**Architecture:**
- `flake.nix`: Entry point defining inputs (nixpkgs) and outputs.
- `hosts/`: Machine-specific configurations (e.g., `hosts/nixos/`).
- `modules/system/`: Reusable system modules:
    - `boot.nix`: Kernel (Zen), Bootloader (systemd-boot), Encryption (LUKS).
    - `gaming.nix`: Steam, Gamemode, Kernel tweaks.
    - `input.nix`: Kanata service, uinput rules.
    - `desktop.nix`: Niri, Greetd, Fonts.
    - `audio.nix`: PipeWire.
- `home/`: User-specific Home Manager configurations:
    - `home/ovg/default.nix`: Main user config.
    - `home/ovg/niri/`: Niri window manager config (`config.kdl`, `binds.kdl`).
    - `home/ovg/kanata.kbd`: Keyboard remapping configuration.
    - `home/ovg/web-apps.nix`: Declarative web apps (Chromium app mode).
    - `home/ovg/scripts/`: Custom maintenance scripts.

## Key Features & Subsystems

### ⌨️ Input & Accessibility
- **Kanata**: Advanced keyboard remapping implementing "Home Row Mods" (A/S/D/F as modifiers).
    - *Config:* `home/ovg/kanata.kbd`
    - *System Service:* `modules/system/input.nix`

### 🪟 Window Management
- **Niri**: Scrollable-tiling Wayland compositor.
    - *Config:* `home/ovg/niri/`
    - *Status Bar:* Waybar (`home/ovg/waybar/`)
    - *Launcher:* Wofi (`home/ovg/wofi/`)
    - *Notifications:* Mako (`home/ovg/mako/`)

### 🎮 Gaming & Performance
- **Optimizations**:
    - **Kernel**: Linux Zen Kernel (`modules/system/boot.nix`).
    - **Gamemode**: Automatic performance tweaks.
    - **Kernel Parameters**: `split_lock_detect=off`, `preempt=full`, `vm.max_map_count` increased.
- **Tools**: Steam (with gamescope), Lutris, ProtonTricks.

### 🌐 Web & Networking
- **Browsers**: Zen Browser, Chromium.
- **Web Apps**: Declaratively defined in `home/ovg/web-apps.nix` (YouTube, Apple Music, etc.).

### 📝 Development Environment
- **Editor**: Neovim (`home/ovg/nvim/`) - Lua config.
- **Terminal**: Ghostty (`home/ovg/ghostty/`) - GPU-accelerated with custom shaders.
- **Shell**: Fish and Bash with aliases.

## Workflows

### Rebuilding the System (Preferred Method)
A custom script handles git staging, committing, pushing, and rebuilding in one go.
```bash
./home/ovg/scripts/nixos-rebuild-with-git.sh
```

### Rebuilding (Standard Method)
- **Switch:** `sudo nixos-rebuild switch --flake .#nixos`
- **Test:** `sudo nixos-rebuild test --flake .#nixos`

### Maintenance
- **Update Flake Inputs:** `sudo nix flake update`
- **Clean Garbage:** Run the `clean-nix` alias (defined in `home/ovg/default.nix`).

## Customization Guide

- **Adding System Packages**: Edit `modules/system/desktop.nix` (or relevant module).
- **Adding User Packages**: Edit `home.packages` in `home/ovg/default.nix`.
- **Adding Web Apps**: Add entries to `webApps` list in `home/ovg/web-apps.nix`.
- **Modifying Keybinds**: Edit `home/ovg/kanata.kbd` (remapping) or `home/ovg/niri/binds.kdl` (WM).
