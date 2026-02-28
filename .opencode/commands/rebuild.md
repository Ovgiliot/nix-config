---
description: Format all modified .nix files with alejandra, build the NixOS configuration to validate it, and stage the changes if successful.
agent: build
---
Run the following steps in order. Stop and report the error immediately if any step fails.

1. Run `alejandra .` to format all Nix files in the repo.
2. Determine the current hostname by running `hostname -s`. Use it as the flake target (e.g. `.#nixos` if the hostname is `nixos`).
3. Run `nixos-rebuild build --flake .#<hostname>` to validate the configuration. This requires no activation and is safe to run at any time.
4. If the build succeeds, run `git add -A` to stage all changes.
5. Report the result. If the build succeeded, remind the user to run `sudo nixos-rebuild switch --flake .#<hostname>` to activate.
6. If the build failed, analyse the error output carefully, identify the root cause, propose a fix, and ask for confirmation before applying it.
