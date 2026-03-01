#!/usr/bin/env bash
# install.sh — Interactive bootstrap for a new machine.
#
# Two modes:
#   Live ISO  — Detected automatically when / is a tmpfs (NixOS installer env).
#               Prompts for a target disk, partitions it with disko, installs
#               NixOS, and copies the dotfiles repo into the new system.
#   Installed — Runs on an already-booted NixOS system.  Creates a host entry
#               under hosts/<hostname>/ and runs nixos-rebuild switch.
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

prompt_secret() {
	# Like prompt but disables echo. Result stored in the named variable.
	local var="$1" msg="$2"
	printf '%s: ' "$msg"
	read -rs "$var"
	printf '\n'
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
# Architecture detection (Linux only)
# ---------------------------------------------------------------------------
LINUX_SYSTEM="x86_64-linux"
if [[ "$PLATFORM" == "linux" ]]; then
	case "$(uname -m)" in
	x86_64) LINUX_SYSTEM="x86_64-linux" ;;
	aarch64) LINUX_SYSTEM="aarch64-linux" ;;
	*) die "Unsupported Linux architecture: $(uname -m)" ;;
	esac
	info "Detected system: $LINUX_SYSTEM"
fi

# ---------------------------------------------------------------------------
# Live ISO detection (Linux only)
# ---------------------------------------------------------------------------
# The NixOS minimal installer mounts / as a tmpfs. We treat this as the signal
# that we are running inside the live environment and should do a fresh install
# rather than a nixos-rebuild switch.
LIVE_ISO=false
if [[ "$PLATFORM" == "linux" ]] && grep -q '^tmpfs / tmpfs' /proc/mounts 2>/dev/null; then
	LIVE_ISO=true
	info "Live ISO environment detected — fresh install mode."
fi

# ---------------------------------------------------------------------------
# Ensure Nix is installed
# ---------------------------------------------------------------------------
if ! command -v nix &>/dev/null; then
	warn "Nix not found — installing via the Determinate Systems installer..."
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
		sh -s -- install --no-confirm ||
		die "Nix installation failed. Install manually: https://determinate.systems/nix"

	# Make nix available in the current shell without requiring a restart.
	NIX_PROFILE="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
	# shellcheck source=/dev/null
	[[ -f "$NIX_PROFILE" ]] && source "$NIX_PROFILE" ||
		die "Nix installed but profile not found at $NIX_PROFILE — open a new shell and re-run."

	ok "Nix installed and available."
fi

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
# Profile-specific inputs (Linux desktop profiles)
# ---------------------------------------------------------------------------
SWAP_LUKS_UUID=""
KANATA_DEVICE=""
VIDEO_ACCEL=""

if [[ "$PROFILE" == "laptop" || "$PROFILE" == "workstation" ]]; then
	choose VIDEO_ACCEL "GPU vendor (for hardware video acceleration):" "intel" "amd" "none"
	info "Video acceleration: $VIDEO_ACCEL"

	# Default is the ThinkPad / most-common PS/2 keyboard by-path alias.
	# Adjust if your machine uses a USB keyboard or a different path.
	DEFAULT_KBD="/dev/input/by-path/platform-i8042-serio-0-event-kbd"
	prompt KANATA_DEVICE "Keyboard device path for Kanata" "$DEFAULT_KBD"
	info "Kanata device: $KANATA_DEVICE"
fi

if [[ "$PROFILE" == "laptop" ]] && [[ "$LIVE_ISO" == false ]]; then
	# On an already-installed system the swap partition already exists; just
	# capture the LUKS UUID for hibernate support.
	warn "Laptop profile requires the swap LUKS UUID for hibernate support."
	warn "Find it with: lsblk -o NAME,UUID | grep luks"
	prompt SWAP_LUKS_UUID "Swap LUKS UUID (leave empty to skip hibernate setup)"
fi

# ---------------------------------------------------------------------------
# Live ISO: disk setup prompts
# ---------------------------------------------------------------------------
TARGET_DISK=""
ENCRYPT=""
LUKS_PASSPHRASE=""
SWAP_SIZE=""

if [[ "$LIVE_ISO" == true ]]; then
	echo ""
	info "Available block devices:"
	lsblk -o NAME,SIZE,TYPE,MODEL | grep -v loop || true
	echo ""
	prompt TARGET_DISK "Target disk (e.g. /dev/sda or /dev/nvme0n1)"
	[[ -b "$TARGET_DISK" ]] || die "Not a block device: $TARGET_DISK"

	choose ENCRYPT "Encrypt the disk with LUKS?" "yes" "no"
	if [[ "$ENCRYPT" == "yes" ]]; then
		prompt_secret LUKS_PASSPHRASE "LUKS passphrase"
		LUKS_CONFIRM=""
		prompt_secret LUKS_CONFIRM "Confirm LUKS passphrase"
		[[ "$LUKS_PASSPHRASE" == "$LUKS_CONFIRM" ]] || die "Passphrases do not match."
		unset LUKS_CONFIRM
	fi

	if [[ "$PROFILE" == "laptop" ]]; then
		prompt SWAP_SIZE "Swap partition size (e.g. 16G — should match RAM for hibernate)" "16G"
		info "Swap size: $SWAP_SIZE"
	fi
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
# Generate hosts/<hostname>/disko.nix  (live ISO installs only)
# ---------------------------------------------------------------------------
if [[ "$LIVE_ISO" == true ]]; then
	info "Resolving disk ID for $TARGET_DISK..."
	# Prefer stable /dev/disk/by-id path; fall back to raw device if unavailable.
	DISK_BY_ID=$(readlink -f /dev/disk/by-id/* 2>/dev/null |
		awk -v dev="$TARGET_DISK" '
      $0 == dev { found=FILENAME }
      END { print found }
    ' 2>/dev/null || true)
	# awk over /dev/disk/by-id symlinks is fiddly; use a simpler approach:
	DISK_BY_ID=""
	while IFS= read -r link; do
		if [[ "$(readlink -f "$link")" == "$TARGET_DISK" ]]; then
			DISK_BY_ID="$link"
			break
		fi
	done < <(find /dev/disk/by-id -maxdepth 1 -type l 2>/dev/null | sort)
	if [[ -z "$DISK_BY_ID" ]]; then
		warn "No by-id symlink found for $TARGET_DISK — using raw device path."
		DISK_BY_ID="$TARGET_DISK"
	else
		info "Disk ID: $DISK_BY_ID"
	fi

	info "Writing hosts/$HOSTNAME/disko.nix..."

	if [[ "$ENCRYPT" == "yes" ]]; then
		if [[ "$PROFILE" == "laptop" ]]; then
			# Encrypted: ESP + LUKS swap + LUKS root
			cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Disk layout for ${HOSTNAME} — GPT, LUKS-encrypted swap + root.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk.main = {
    type = "disk";
    device = "${DISK_BY_ID}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        swap = {
          size = "${SWAP_SIZE}";
          content = {
            type = "luks";
            name = "cryptswap";
            settings.allowDiscards = true;
            content = {
              type = "swap";
            };
          };
        };
        root = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = ["noatime"];
            };
          };
        };
      };
    };
  };
}
NIXEOF
		else
			# Encrypted: ESP + LUKS root (workstation / server)
			cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Disk layout for ${HOSTNAME} — GPT, LUKS-encrypted root.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk.main = {
    type = "disk";
    device = "${DISK_BY_ID}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = ["noatime"];
            };
          };
        };
      };
    };
  };
}
NIXEOF
		fi
	else
		if [[ "$PROFILE" == "laptop" ]]; then
			# Unencrypted: ESP + swap + root
			cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Disk layout for ${HOSTNAME} — GPT, unencrypted swap + root.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk.main = {
    type = "disk";
    device = "${DISK_BY_ID}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        swap = {
          size = "${SWAP_SIZE}";
          content = {
            type = "swap";
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["noatime"];
          };
        };
      };
    };
  };
}
NIXEOF
		else
			# Unencrypted: ESP + root (workstation / server)
			cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Disk layout for ${HOSTNAME} — GPT, unencrypted root.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk.main = {
    type = "disk";
    device = "${DISK_BY_ID}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["noatime"];
          };
        };
      };
    };
  };
}
NIXEOF
		fi
	fi
	ok "hosts/$HOSTNAME/disko.nix written."
fi

# ---------------------------------------------------------------------------
# Generate hosts/<hostname>/default.nix
# ---------------------------------------------------------------------------
info "Writing hosts/$HOSTNAME/default.nix..."

# disko.nix is included in the modules list for live ISO installs so that the
# installed system picks up the filesystem declarations for future rebuilds.
DISKO_MODULE=""
if [[ "$LIVE_ISO" == true ]]; then
	DISKO_MODULE="
    inputs.disko.nixosModules.disko
    ./disko.nix"
fi

if [[ "$PROFILE" == "laptop" ]]; then

	cat >"$HOST_DIR/default.nix" <<NIXEOF
# ThinkPad / Laptop host — uses the laptop profile.
{inputs}: let
  dotfilesDir = ../../home/ovg;
in {
  system = "${LINUX_SYSTEM}";

  specialArgs = {
    inherit inputs dotfilesDir;
    swapLuksUuid = "${SWAP_LUKS_UUID}";
    kanataConfig = dotfilesDir + "/kanata.kbd";
    kanataDevice = "${KANATA_DEVICE}";
    videoAcceleration = "${VIDEO_ACCEL}";
  };

  modules = [
    ../../profiles/laptop.nix
    ./hardware.nix${DISKO_MODULE}
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
  system = "${LINUX_SYSTEM}";

  specialArgs = {
    inherit inputs dotfilesDir;
    kanataConfig = dotfilesDir + "/kanata.kbd";
    kanataDevice = "${KANATA_DEVICE}";
    videoAcceleration = "${VIDEO_ACCEL}";
  };

  modules = [
    ../../profiles/workstation.nix
    ./hardware.nix${DISKO_MODULE}
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
  system = "${LINUX_SYSTEM}";

  specialArgs = {
    inherit inputs dotfilesDir;
  };

  modules = [
    ../../profiles/server.nix
    ./hardware.nix${DISKO_MODULE}
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
	# Insert the new entry on the line before the marker.
	# awk is used instead of sed -i because BSD sed (macOS) requires a different
	# -i syntax and does not support \n in replacement strings.
	awk -v entry="      ${ENTRY}" -v marker="${MARKER}" '
		index($0, marker) > 0 { print entry }
		{ print }
	' "$FLAKE_DIR/flake.nix" >"$FLAKE_DIR/flake.nix.tmp" &&
		mv "$FLAKE_DIR/flake.nix.tmp" "$FLAKE_DIR/flake.nix"
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
info "Formatting hosts/$HOSTNAME/ with alejandra..."
alejandra "$HOST_DIR/" 2>/dev/null ||
	warn "alejandra not in PATH — skipping format (run 'nix fmt' later)."

# ---------------------------------------------------------------------------
# Build / Install
# ---------------------------------------------------------------------------
info "Ready to build .#$HOSTNAME"
printf 'Proceed? [Y/n]: '
read -r yn
[[ "$yn" =~ ^[Nn]$ ]] && {
	info "Skipped. Run manually:"
	if [[ "$LIVE_ISO" == true ]]; then
		echo "  sudo disko --mode disko $HOST_DIR/disko.nix"
		echo "  sudo nixos-generate-config --root /mnt --show-hardware-config > $HOST_DIR/hardware.nix"
		echo "  sudo nixos-install --flake .#${HOSTNAME} --root /mnt --no-root-passwd"
	elif [[ "$PLATFORM" == "linux" ]]; then
		echo "  sudo nixos-rebuild switch --flake .#${HOSTNAME}"
	else
		echo "  darwin-rebuild switch --flake .#${HOSTNAME}"
	fi
	exit 0
}

if [[ "$LIVE_ISO" == true ]]; then
	# ------------------------------------------------------------------
	# Live ISO: partition → install → copy dotfiles
	# ------------------------------------------------------------------
	info "Partitioning $TARGET_DISK with disko..."
	if [[ "$ENCRYPT" == "yes" ]]; then
		# Supply the LUKS passphrase non-interactively via a key file so disko
		# doesn't prompt once per LUKS partition.
		KEYFILE="$(mktemp)"
		printf '%s' "$LUKS_PASSPHRASE" >"$KEYFILE"
		sudo disko --mode disko \
			--arg passwordFile "\"$KEYFILE\"" \
			"$HOST_DIR/disko.nix" || {
			rm -f "$KEYFILE"
			die "disko failed."
		}
		rm -f "$KEYFILE"
	else
		sudo disko --mode disko "$HOST_DIR/disko.nix" || die "disko failed."
	fi
	ok "Disk partitioned and mounted at /mnt."

	# Capture LUKS UUIDs after disko has created the partitions.
	# Partition order: ESP=1, (swap=2 if laptop), root=last.
	if [[ "$PROFILE" == "laptop" && "$ENCRYPT" == "yes" ]]; then
		# Determine the swap partition: 2nd partition on the disk.
		# Works for both /dev/sda2 and /dev/nvme0n1p2 naming conventions.
		if [[ "$TARGET_DISK" == *nvme* ]]; then
			SWAP_PART="${TARGET_DISK}p2"
		else
			SWAP_PART="${TARGET_DISK}2"
		fi
		SWAP_LUKS_UUID="$(blkid -s UUID -o value "$SWAP_PART")" ||
			warn "Could not read swap LUKS UUID — hibernate may not work."
		info "Swap LUKS UUID: $SWAP_LUKS_UUID"
		# Patch the placeholder UUID in default.nix.
		sed -i "s/swapLuksUuid = \"\";/swapLuksUuid = \"${SWAP_LUKS_UUID}\";/" \
			"$HOST_DIR/default.nix" || true
	fi

	info "Generating hardware configuration..."
	sudo nixos-generate-config --root /mnt --show-hardware-config \
		>"$HOST_DIR/hardware.nix" ||
		die "nixos-generate-config failed."
	ok "hardware.nix written."

	# Re-format after hardware.nix was written.
	alejandra "$HOST_DIR/" 2>/dev/null || true

	info "Running nixos-install for .#$HOSTNAME ..."
	cd "$FLAKE_DIR"
	sudo nixos-install \
		--flake ".#${HOSTNAME}" \
		--root /mnt \
		--no-root-passwd ||
		die "nixos-install failed."
	ok "NixOS installed."

	# Copy dotfiles into the new system so they are available after reboot.
	info "Copying dotfiles to /mnt/home/ovg/dotfiles/nix ..."
	sudo mkdir -p /mnt/home/ovg/dotfiles
	sudo cp -rT "$FLAKE_DIR" /mnt/home/ovg/dotfiles/nix
	# ovg uid=1000 gid=1000 (standard NixOS first user).
	sudo chown -R 1000:1000 /mnt/home/ovg/
	ok "Dotfiles copied."

	ok "Installation complete. Remove the USB and reboot."
	echo "  reboot"

elif [[ "$PLATFORM" == "linux" ]]; then
	# ------------------------------------------------------------------
	# Installed system: generate hardware config + rebuild
	# ------------------------------------------------------------------
	info "Generating hardware configuration..."
	nixos-generate-config --show-hardware-config 2>/dev/null \
		>"$HOST_DIR/hardware.nix" ||
		die "nixos-generate-config failed. Run this script as root or with sudo."
	ok "hardware.nix written."

	alejandra "$HOST_DIR/" 2>/dev/null || true

	info "Running nixos-rebuild switch for .#$HOSTNAME ..."
	cd "$FLAKE_DIR"
	sudo nixos-rebuild switch --flake ".#${HOSTNAME}"
	ok "Build complete. This machine is now '${HOSTNAME}' running the '${PROFILE}' profile."

else
	# ------------------------------------------------------------------
	# macOS: darwin-rebuild
	# ------------------------------------------------------------------
	cd "$FLAKE_DIR"
	if command -v darwin-rebuild &>/dev/null; then
		darwin-rebuild switch --flake ".#${HOSTNAME}"
	else
		info "darwin-rebuild not found — using nix run for first activation..."
		nix run nix-darwin -- switch --flake ".#${HOSTNAME}"
	fi
	ok "Build complete. This machine is now '${HOSTNAME}' running the '${PROFILE}' profile."
	printf '\n'
	info "Kanata is installed but requires a one-time manual driver setup on macOS."
	info "Install the Karabiner-Elements virtual HID driver, then run kanata as root:"
	echo "  https://github.com/jtroo/kanata/blob/main/docs/macos.md"
	echo "  sudo kanata --cfg ~/.config/kanata/kanata.kbd"
fi
