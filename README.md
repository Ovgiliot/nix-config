# NixOS Configuration

This repository contains a modular and reproducible **NixOS** configuration, managed with **Nix Flakes** and **Home Manager**. It provides a comprehensive setup for a modern Linux desktop environment, tailored for performance, gaming, and productivity, featuring **Niri** (a scrollable-tiling Wayland compositor) and **KDE Plasma 6**.

## 📂 Project Structure

The configuration is organized to separate system-level settings from user-specific dotfiles.

```
.
├── flake.nix             # Entry point: Defines inputs (nixpkgs) and outputs (system configs).
├── hosts/                # Machine-specific configurations.
│   └── nixos/            # Main host 'nixos'.
│       ├── configuration.nix      # Imports system modules.
│       └── hardware-configuration.nix # Hardware scan (do not edit manually).
├── modules/              # Reusable NixOS modules.
│   └── system/           # System-wide settings.
│       ├── boot.nix      # Bootloader & Kernel (Zen).
│       ├── gaming.nix    # Steam, Gamemode, Kernel tweaks.
│       ├── desktop.nix   # Niri, Greetd, Fonts.
│       ├── audio.nix     # PipeWire.
│       └── ...           # Networking, Locale, etc.
└── home/                 # User-specific configurations (Home Manager).
    └── ovg/              # User 'ovg'.
        ├── default.nix   # Main user config entry point.
        ├── kanata.kbd    # Keyboard remapping config.
        ├── web-apps.nix  # Declarative web applications.
        ├── niri/         # Window manager config.
        ├── scripts/      # Custom maintenance scripts.
        ├── ...           # Other dotfiles (nvim, ghostty, waybar, etc.).
```

## ⚡ Quick Start

### 1. Initial Setup
```bash
# Clone the repository
git clone <repo-url> ~/dotfiles/nix
cd ~/dotfiles/nix

# Update flake inputs (optional)
sudo nix flake update
```

### 2. Rebuilding the System
You can use standard NixOS commands, but a helper script is included to manage git state and rebuilds simultaneously.

**Standard Method:**
```bash
sudo nixos-rebuild switch --flake .#nixos
```

**Custom Script (Recommended):**
Location: `home/ovg/scripts/nixos-rebuild-with-git.sh`
Usage:
```bash
./home/ovg/scripts/nixos-rebuild-with-git.sh
```
*   Automatically stages and commits changes.
*   Pushes to remote (handling upstream branches).
*   Rebuilds the system only if the git operations succeed.

### 3. Maintenance
*   **Clean Garbage:** `clean-nix` (Shell alias defined in `home/ovg/default.nix`) - Deletes old generations and optimizes the store.

---

## 🛠️ System Configuration

### 🖥️ Desktop & Window Management
*   **Compositor:** **Niri** (Scrollable Tiling Wayland)
    *   *Config:* `home/ovg/niri/`
    *   *Features:* Infinite scrolling layout, custom binds, window rules.
*   **Display Manager:** `tuigreet` (Text-based, minimalist) -> launches `niri-session`.
*   **Status Bar:** **Waybar** (`home/ovg/waybar/`) - styled with CSS.
*   **Launcher:** **Wofi** (`home/ovg/wofi/`) - includes custom scripts for WiFi and Bluetooth.
*   **Notifications:** **Mako** (`home/ovg/mako/`).
*   **Theming:** GTK (`adw-gtk3-dark`) and QT (`adwaita-dark`) are unified for a consistent dark mode experience (`home/ovg/default.nix`).

### ⌨️ Input & Accessibility
*   **Keyboard Remapping:** **Kanata**
    *   *Config:* `home/ovg/kanata.kbd`
    *   *Function:* Implements "Home Row Mods" (A/S/D/F act as Super/Ctrl/Shift/Alt when held).
    *   *Service:* `modules/system/input.nix` handles the `uinput` permissions and service.
*   **Layouts:** configured for US and RU, switching with `Ctrl+Space`.

### 🎮 Gaming & Performance
*   *Config:* `modules/system/gaming.nix`
*   **Kernel:** **Linux Zen** (`modules/system/boot.nix`) for improved desktop responsiveness.
*   **Optimizations:**
    *   **GameMode:** Automatically applies performance tweaks when games run.
    *   **Kernel Parameters:** `split_lock_detect=off`, `preempt=full`, `vm.max_map_count` increased (essential for Steam/Proton).
*   **Software:** Steam (with gamescope), Lutris, ProtonTricks.

### 🌐 Networking & Web
*   **Network:** NetworkManager enabled (`modules/system/networking.nix`).
*   **Browsers:** Zen Browser, Chromium (for web apps).
*   **Web Apps:** `home/ovg/web-apps.nix`
    *   Declaratively creates desktop entries for sites like YouTube, Apple Music, and Nix Search using Chromium's app mode.

### 🛠️ Core System
*   **Boot:** systemd-boot with EFI support.
*   **Encryption:** LUKS configuration for secure storage (`modules/system/boot.nix`).
*   **Locale:** Kyiv time zone, English (US) system language with Ukrainian locale formats (`modules/system/locale.nix`).
*   **Nix Settings:** Flakes enabled, automatic weekly garbage collection (`modules/system/nix.nix`).

### 📝 Development
*   **Editor:** **Neovim** (`home/ovg/nvim/`) - Full Lua configuration.
*   **Terminal:** **Ghostty** (`home/ovg/ghostty/`) - GPU-accelerated, custom shaders (`cursor_warp.glsl`).
*   **Shell:** Fish and Bash configured with aliases.

---

## 🏗️ Adding New Features

*   **New System Package:** Edit `modules/system/desktop.nix` (or relevant module) and rebuild.
*   **New User App:** Add to `home.packages` in `home/ovg/default.nix`.
*   **New Web App:** Add an entry to the `webApps` list in `home/ovg/web-apps.nix`.