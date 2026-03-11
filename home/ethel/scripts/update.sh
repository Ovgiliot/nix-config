#!/usr/bin/env bash

# --- NixOS Update with Preview ---
# Updates flake inputs, builds the new configuration, shows a store diff,
# and asks for confirmation before switching.

set -euo pipefail

REPO_PATH="/home/ethel/dotfiles/nix-config"
HOSTNAME="$(hostname -s)"

cd "$REPO_PATH" || {
	echo "Error: Could not navigate to $REPO_PATH"
	exit 1
}

echo "=== NixOS Update: .#${HOSTNAME} ==="
echo

echo "==> Updating flake inputs..."
nix flake update

echo
echo "==> Building new configuration..."
nixos-rebuild build --flake ".#${HOSTNAME}"

echo
echo "==> Closure diff:"
nix store diff-closures /run/current-system ./result
rm -f result

echo
read -r -p "Apply updates? (y/N) " response
echo

if [[ "$response" == "y" || "$response" == "Y" ]]; then
	sudo nixos-rebuild switch --flake ".#${HOSTNAME}"
	echo "Done."
else
	echo "Cancelled — reverting flake.lock."
	git checkout flake.lock
fi

echo
read -n 1 -s -r -p "Press any key to close"
