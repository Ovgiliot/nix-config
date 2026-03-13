# NixOS Dotfiles

A modular, multi-profile NixOS and macOS configuration using **Nix Flakes** and **Home Manager**, following the Suckless philosophy: minimalism, clarity, and explicit configuration over magic defaults.

**Desktop:** Niri (scrollable-tiling Wayland) + QuickShell + Wofi + Mako
**Terminal:** Ghostty | **Editor:** Neovim | **Shell:** Fish
**Input:** Kanata home-row mods | **Audio:** PipeWire
**Theming:** Matugen (Material Design 3 wallpaper-based colors)

---

## How It Works

The config is split into two concepts:

**Infrastructure layers** are composable foundations that form a dependency chain. Each layer imports its own dependencies, so the NixOS module system deduplicates automatically.

```
Core  ←  Server
Core  ←  Desktop  ←  Laptop
```

- **Core** — Boot, nix settings, locale, networking, security, Home Manager base (shell, neovim, CLI tools, git).
- **Server** — Imports core. Adds hardened kernel.
- **Desktop** — Imports core. Adds Niri, PipeWire, greetd, kanata, theming, wallpaper, desktop apps.
- **Laptop** — Imports desktop. Adds ThinkPad power management, bluetooth, zram.

**Workflow modules** are composable feature sets that declare what infrastructure they need and bring both system and home config through a single entry point.

Active workflows: **development**, **gaming**, **browsing**, **virtualization**, **music**, **notetaking**. Scaffold workflows exist for future use (drones, 2d/3d art, video editing, game dev, VR, smart home, home lab).

**Profiles** are thin composition layers that pick one infrastructure layer and a set of workflows:

```nix
# profiles/laptop.nix
{ imports = [
    ../modules/system/laptop
    ../modules/system/workflows/virtualization.nix
    ../modules/system/workflows/development.nix
    ../modules/system/workflows/browsing.nix
    ../modules/system/workflows/music.nix
    ../modules/system/workflows/notetaking.nix
  ];
}
```

Each host picks a profile and adds its hardware config. That's it.

---

## Project Layout

```
flake.nix                    # Entry point — helpers, checks, formatter
profiles/                    # Thin composition: 1 infra layer + N workflows
hosts/<hostname>/            # Per-machine: hardware.nix + specialArgs
modules/system/
  core/                      # Every NixOS machine
  server/                    # Headless
  desktop/                   # Wayland compositor + audio + input
  laptop/                    # ThinkPad power + services
  workflows/                 # 14 workflow entry points
modules/home/
[/home/ethel/.config/glava/rc.glsl:11] unknown request type 'setdecorate' core/                      # Shell, neovim (base), CLI, git, keymap
  desktop/                   # Theme, niri, quickshell, ghostty, wallpaper, apps
  laptop/                    # Power monitor, touchpad
  darwin/                    # macOS overrides
  workflows/                 # 11 home workflow modules
  lib.nix                    # Shared helpers (stripShebang, mkDesktopFile)
home/ethel/                  # Raw dotfiles — linked via XDG by modules/home/
```

---

## Usage

```bash
# Rebuild
sudo nixos-rebuild switch --flake .#<hostname>

# macOS
darwin-rebuild switch --flake .#<hostname>

# Update flake inputs
nix flake update

# Format all .nix files
nix fmt

# Run all checks (eval, build, integrity, format, VM test)
nix flake check

# Run a single check
nix build .#checks.x86_64-linux.<name>

# Garbage collect (fish alias)
clean-nix
```

Available checks: `nixos-build`, `server-build`, `workstation-build`, `server-eval`, `workstation-eval`, `dotfiles-integrity`, `fmt`, `server-vm-test`.

---

## Adding a New Host

1. Generate `hosts/<hostname>/hardware.nix` with `nixos-generate-config`.
2. Create `hosts/<hostname>/default.nix` exporting `{ system, specialArgs, modules }`.
3. Add `<hostname> = mkNixosHost "<hostname>";` to `flake.nix`.
4. `nix fmt && sudo nixos-rebuild build --flake .#<hostname>`

## Adding a New Workflow

1. Create `modules/system/workflows/<name>.nix` — import the required infra layer, add system config, append the home module to `home-manager.users.ethel.imports`.
2. Optionally create `modules/home/workflows/<name>.nix` for user-side config.
3. Add the workflow to the relevant profile(s) in `profiles/`.
4. `nix fmt && nix flake check`

---

## Deep Dive

See [AGENTS.md](AGENTS.md) for the full architecture reference: infrastructure layer details, all workflow modules, specialArgs, architecture rules, keyboard layout mapping system, color theming, flake checks, and conventions.
