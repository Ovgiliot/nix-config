---
description: Run configuration stability checks. Pass "full" to include complete system builds and the server VM test.
agent: build
---
Run NixOS configuration stability checks after recent changes. Stop immediately on any failure, diagnose and fix, then re-run the failing check before continuing.

Run these four checks in order:

1. `nix build .#checks.x86_64-linux.fmt` — all .nix files are formatted with alejandra
2. `nix build .#checks.x86_64-linux.dotfiles-integrity` — all paths in home/ethel/ referenced by xdg.configFile exist
3. `nix build .#checks.x86_64-linux.server-eval` — server profile evaluates without errors
4. `nix build .#checks.x86_64-linux.workstation-eval` — workstation profile evaluates without errors

If $ARGUMENTS is "full": run `nix flake check` instead of the four individual commands above. This also runs nixos-build, server-build, workstation-build, and the server VM test — expect it to take significantly longer.

On any failure:
- Read the error output carefully to identify the root cause.
- Apply the fix.
- Re-run the failing check to confirm it passes before continuing.

Report all results at the end.
