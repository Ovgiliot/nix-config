#!/usr/bin/env bash
# install.sh — Interactive bootstrap for a new machine.
#
# Creates a host entry under hosts/<hostname>/, injects it into flake.nix,
# sets the system hostname, and runs the initial build.
#
# Usage: bash install.sh
set -euo pipefail

FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info() { printf '\033[1;34m==> \033[0m%s\n' "$*"; }
ok() { printf '\033[1;32m ok \033[0m%s\n' "$*"; }
warn() { printf '\033[1;33mwarn\033[0m %s\n' "$*"; }
die() {
	printf '\033[1;31merr \033[0m%s\n' "$*" >&2
	exit 1
}

prompt() {
	local var="$1" msg="$2" default="${3:-}"
	local hint=""
	[[ -n "$default" ]] && hint=" [$default]"
	printf '%s%s: ' "$msg" "$hint"
	read -r "$var"
	if [[ -z "${!var}" && -n "$default" ]]; then
		printf -v "$var" '%s' "$default"
	fi
	[[ -z "${!var}" ]] && die "Required value not provided."
}

choose() {
	# choose VAR "prompt" option1 option2 ...
	local var="$1" msg="$2"
	shift 2
	local opts=("$@")
	echo "$msg"
	for i in "${!opts[@]}"; do
		printf '  %d) %s\n' "$((i + 1))" "${opts[$i]}"
	done
	local choice
	while true; do
		printf 'Choice [1-%d]: ' "${#opts[@]}"
		read -r choice
		if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#opts[@]})); then
			printf -v "$var" '%s' "${opts[$((choice - 1))]}"
			return
		fi
		warn "Enter a number between 1 and ${#opts[@]}."
	done
}

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------
PLATFORM="$(uname -s)"
case "$PLATFORM" in
Linux) PLATFORM="linux" ;;
Darwin) PLATFORM="darwin" ;;
*) die "Unsupported platform: $PLATFORM" ;;
esac
info "Detected platform: $PLATFORM"

# ---------------------------------------------------------------------------
# Profile selection
# ---------------------------------------------------------------------------
if [[ "$PLATFORM" == "darwin" ]]; then
	PROFILE="darwin"
	info "macOS detected — using darwin profile."
else
	choose PROFILE "Select a profile:" "laptop" "workstation" "server"
fi
info "Profile: $PROFILE"

# ---------------------------------------------------------------------------
# Hostname
# ---------------------------------------------------------------------------
CURRENT_HOSTNAME="$(hostname -s 2>/dev/null || echo '')"
prompt HOSTNAME "Hostname for this machine" "$CURRENT_HOSTNAME"
info "Hostname: $HOSTNAME"

# ---------------------------------------------------------------------------
# Profile-specific inputs
# ---------------------------------------------------------------------------
SWAP_LUKS_UUID=""
if [[ "$PROFILE" == "laptop" ]]; then
	warn "Laptop profile requires the swap LUKS UUID for hibernate support."
	warn "Find it with: lsblk -o NAME,UUID | grep luks"
	prompt SWAP_LUKS_UUID "Swap LUKS UUID (leave empty to skip hibernate setup)"
fi

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------
HOST_DIR="$FLAKE_DIR/hosts/$HOSTNAME"
if [[ -d "$HOST_DIR" ]]; then
	warn "Host directory $HOST_DIR already exists."
	printf 'Overwrite? [y/N]: '
	read -r yn
	[[ "$yn" =~ ^[Yy]$ ]] || die "Aborted."
fi
mkdir -p "$HOST_DIR"

# ---------------------------------------------------------------------------
# Hardware configuration (Linux only)
# ---------------------------------------------------------------------------
if [[ "$PLATFORM" == "linux" ]]; then
	info "Generating hardware configuration..."
	nixos-generate-config --show-hardware-config 2>/dev/null >"$HOST_DIR/hardware.nix" ||
		die "nixos-generate-config failed. Run this script as root or with sudo."
	ok "hardware.nix written."
fi

# ---------------------------------------------------------------------------
# Generate hosts/<hostname>/default.nix
# ---------------------------------------------------------------------------
info "Writing hosts/$HOSTNAME/default.nix..."

if [[ "$PROFILE" == "laptop" ]]; then

	cat >"$HOST_DIR/default.nix" <<NIXEOF
# ThinkPad / Laptop host — uses the laptop profile.
{inputs}: let
  dotfilesDir = ../../home/ovg;
in {
  system = "x86_64-linux";

  specialArgs = {
    inherit inputs dotfilesDir;
    swapLuksUuid = "${SWAP_LUKS_UUID}";
    kanataConfig = dotfilesDir + "/kanata.kbd";
  };

  modules = [
    ../../profiles/laptop.nix
    ./hardware.nix
    ({pkgs, ...}: {
      networking.hostName = "${HOSTNAME}";

      programs.fish.enable = true;

      users.users.ovg = {
        isNormalUser = true;
        shell = pkgs.fish;
        description = "ovg";
        extraGroups = ["networkmanager" "wheel" "input" "uinput" "video"];
      };

      system.stateVersion = "25.11";

      home-manager.users.ovg = {
        home.username = "ovg";
        home.homeDirectory = "/home/ovg";
        home.stateVersion = "25.11";
      };
    })
  ];
}
NIXEOF

elif [[ "$PROFILE" == "workstation" ]]; then

	cat >"$HOST_DIR/default.nix" <<NIXEOF
# Workstation host — uses the workstation profile.
{inputs}: let
  dotfilesDir = ../../home/ovg;
in {
  system = "x86_64-linux";

  specialArgs = {
    inherit inputs dotfilesDir;
    # Kanata keyboard device path may differ; adjust input.nix if needed.
    kanataConfig = dotfilesDir + "/kanata.kbd";
  };

  modules = [
    ../../profiles/workstation.nix
    ./hardware.nix
    ({pkgs, ...}: {
      networking.hostName = "${HOSTNAME}";

      programs.fish.enable = true;

      users.users.ovg = {
        isNormalUser = true;
        shell = pkgs.fish;
        description = "ovg";
        extraGroups = ["networkmanager" "wheel" "input" "uinput" "video"];
      };

      system.stateVersion = "25.11";

      home-manager.users.ovg = {
        home.username = "ovg";
        home.homeDirectory = "/home/ovg";
        home.stateVersion = "25.11";
      };
    })
  ];
}
NIXEOF

elif [[ "$PROFILE" == "server" ]]; then

	cat >"$HOST_DIR/default.nix" <<NIXEOF
# Headless server host — uses the server profile.
{inputs}: let
  dotfilesDir = ../../home/ovg;
in {
  system = "x86_64-linux";

  specialArgs = {
    inherit inputs dotfilesDir;
  };

  modules = [
    ../../profiles/server.nix
    ./hardware.nix
    ({pkgs, ...}: {
      networking.hostName = "${HOSTNAME}";

      programs.fish.enable = true;

      users.users.ovg = {
        isNormalUser = true;
        shell = pkgs.fish;
        description = "ovg";
        extraGroups = ["networkmanager" "wheel" "sudo"];
      };

      system.stateVersion = "25.11";

      home-manager.users.ovg = {
        home.username = "ovg";
        home.homeDirectory = "/home/ovg";
        home.stateVersion = "25.11";
      };
    })
  ];
}
NIXEOF

elif [[ "$PROFILE" == "darwin" ]]; then

	# Detect Apple Silicon vs Intel
	DARWIN_SYSTEM="aarch64-darwin"
	[[ "$(uname -m)" == "x86_64" ]] && DARWIN_SYSTEM="x86_64-darwin"

	cat >"$HOST_DIR/default.nix" <<NIXEOF
# macOS host — uses the darwin profile (nix-darwin + home-manager).
{inputs}: let
  dotfilesDir = ../../home/ovg;
in {
  system = "${DARWIN_SYSTEM}";

  specialArgs = {
    inherit inputs dotfilesDir;
  };

  modules = [
    ../../profiles/darwin.nix
    ({pkgs, ...}: {
      networking.hostName = "${HOSTNAME}";

      users.users.ovg = {
        home = "/Users/ovg";
        shell = pkgs.fish;
        description = "ovg";
      };

      # nix-darwin state version — do not change after first activation.
      system.stateVersion = 6;

      home-manager.users.ovg = {
        home.username = "ovg";
        home.homeDirectory = "/Users/ovg";
        home.stateVersion = "25.11";
      };
    })
  ];
}
NIXEOF

fi

ok "hosts/$HOSTNAME/default.nix written."

# ---------------------------------------------------------------------------
# Inject host into flake.nix
# ---------------------------------------------------------------------------
info "Injecting $HOSTNAME into flake.nix..."

if [[ "$PROFILE" == "darwin" ]]; then
	MARKER="# <<DARWIN_HOSTS>>"
	ENTRY="      ${HOSTNAME} = mkDarwinHost \"${HOSTNAME}\";"
else
	MARKER="# <<NIXOS_HOSTS>>"
	ENTRY="      ${HOSTNAME} = mkNixosHost \"${HOSTNAME}\";"
fi

# Only inject if not already present
if grep -q "\"${HOSTNAME}\"" "$FLAKE_DIR/flake.nix"; then
	warn "$HOSTNAME already in flake.nix — skipping injection."
else
	# Insert the new entry on the line before the marker
	sed -i "s|${MARKER}|${ENTRY}\n      ${MARKER}|" "$FLAKE_DIR/flake.nix"
	ok "flake.nix updated."
fi

# ---------------------------------------------------------------------------
# Set system hostname
# ---------------------------------------------------------------------------
info "Setting hostname to '$HOSTNAME'..."
if [[ "$PLATFORM" == "linux" ]]; then
	hostnamectl set-hostname "$HOSTNAME" 2>/dev/null ||
		warn "Could not set hostname (run as root, or set manually with hostnamectl)."
elif [[ "$PLATFORM" == "darwin" ]]; then
	scutil --set HostName "$HOSTNAME" 2>/dev/null ||
		warn "Could not set hostname (run as root, or set manually with scutil)."
fi

# ---------------------------------------------------------------------------
# Format with alejandra
# ---------------------------------------------------------------------------
info "Formatting hosts/$HOSTNAME/default.nix with alejandra..."
alejandra "$HOST_DIR/default.nix" 2>/dev/null ||
	warn "alejandra not in PATH — skipping format (run 'nix fmt' later)."

# ---------------------------------------------------------------------------
# Initial build
# ---------------------------------------------------------------------------
info "Starting initial build for .#$HOSTNAME ..."
printf 'Proceed with the build now? [Y/n]: '
read -r yn
if [[ ! "$yn" =~ ^[Nn]$ ]]; then
	cd "$FLAKE_DIR"
	if [[ "$PLATFORM" == "linux" ]]; then
		sudo nixos-rebuild switch --flake ".#${HOSTNAME}"
	else
		# First run: nix-darwin may not be installed yet
		if command -v darwin-rebuild &>/dev/null; then
			darwin-rebuild switch --flake ".#${HOSTNAME}"
		else
			info "darwin-rebuild not found — using nix run for first activation..."
			nix run nix-darwin -- switch --flake ".#${HOSTNAME}"
		fi
	fi
	ok "Build complete. This machine is now '${HOSTNAME}' running the '${PROFILE}' profile."
else
	info "Skipped build. Run manually:"
	if [[ "$PLATFORM" == "linux" ]]; then
		echo "  sudo nixos-rebuild switch --flake .#${HOSTNAME}"
	else
		echo "  darwin-rebuild switch --flake .#${HOSTNAME}"
	fi
fi
