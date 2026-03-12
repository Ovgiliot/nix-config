# Shared helpers for Home Manager modules.
# Import with: `homeLib = import ../lib.nix {inherit lib;};`
{lib}: {
  # Strip the shebang line produced by shellcheck-compliant scripts so that
  # writeShellApplication can supply its own (strict-mode) header instead.
  stripShebang = text: lib.strings.removePrefix "#!/usr/bin/env bash\n" text;
}
