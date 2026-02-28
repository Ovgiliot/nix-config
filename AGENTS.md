# NixOS Dotfiles

This is a NixOS flake-based configuration using Home Manager, following the **Suckless philosophy**: minimalism, clarity, and explicit configuration over magic defaults.

## Project Structure

- `flake.nix` — Entry point, defines inputs and system outputs.
- `hosts/nixos/` — Machine-specific hardware and system configuration.
- `modules/system/` — Modular, single-responsibility system components (audio, boot, networking, etc.). One concern per file.
- `home/ovg/` — All user-level Home Manager config. The main file is `default.nix`.
- `home/ovg/default.nix` — User packages, shell aliases, GTK/QT theming, XDG config linkage, and systemd user services.

## Architecture Rules

- **System vs User split is strict.** System-level daemons and hardware config go in `modules/system/` or `hosts/nixos/`. User applications, dotfiles, and shell config go in `home/ovg/`.
- **No duplication.** Before adding a package or option, read the relevant file to confirm it is not already declared.
- **Explicit imports only.** Do not use `*` or catch-all imports. Every module must be explicitly listed in `flake.nix` or the relevant `imports` array.
- **XDG linkage.** Dotfiles are linked via `xdg.configFile."<name>".source = ./<path>;` in `home/ovg/default.nix`. Do not write config directly into the Nix store; always link from this repo.

## Suckless Philosophy

- **Minimalism first.** Every added package must justify its existence. Prefer CLI tools over GUI. Prefer composing existing tools over adding new dependencies.
- **No bloat.** Do not add packages "just in case". If it is not used actively, it does not belong here.
- **Readable configs.** Comments should explain *why*, not *what*. Keep configuration files short and scannable.
- **Prefer proven tools.** Established, auditable tools over trendy alternatives.

## Workflow

1. **Before modifying**, read the relevant file fully to understand the current state.
2. **Format** all changed `.nix` files with `alejandra` before considering the task done.
3. **Validate** using the `/rebuild` command, which runs `alejandra` + `nixos-rebuild build`.
4. **Never** use `--impure` unless strictly required and justified.
5. **Git**: stage changes only after a successful build.
