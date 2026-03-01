#!/usr/bin/env bash
# install.sh — Interactive bootstrap for a new machine.
#
# Two modes:
#   Live ISO  — Detected automatically when / is a tmpfs (NixOS installer env).
#               Prompts for disk(s), partitions with disko, installs NixOS,
#               and copies the dotfiles repo into the new system.
#   Installed — Runs on an already-booted NixOS system.  Creates a host entry
#               under hosts/<hostname>/ and runs nixos-rebuild switch.
#
# Partition layout (live ISO):
#   All profiles:  /boot  1 GiB  vfat (ESP)
#   Laptop only:   swap   = RAM  [LUKS]  (hibernate support)
#   All profiles:  /      user-specified or rest-of-disk  ext4  [LUKS]
#   All profiles:  /home  rest of disk (or separate disk) ext4  [LUKS]
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

# Return the partition device for a given disk and partition number.
# Handles both SATA (/dev/sda1) and NVMe/eMMC (/dev/nvme0n1p1) naming.
part() {
	local disk="$1" num="$2"
	if [[ "$disk" == *nvme* || "$disk" == *mmcblk* ]]; then
		echo "${disk}p${num}"
	else
		echo "${disk}${num}"
	fi
}

# Enroll a LUKS partition for TPM2 auto-unlock.
# $1 = block device (the raw LUKS partition, e.g. /dev/sda2)
# $2 = path to a file containing the existing LUKS passphrase
enroll_tpm2() {
	local dev="$1" keyfile="$2"
	info "  Enrolling TPM2 for $dev ..."
	systemd-cryptenroll \
		--tpm2-device=auto \
		--tpm2-pcrs="" \
		--unlock-key-file="$keyfile" \
		"$dev" && ok "  $dev enrolled." ||
		warn "  TPM2 enrollment failed for $dev — enroll manually later with:"$'\n'"    sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=\"\" $dev"
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
SWAP_DEVICE=""
KANATA_DEVICE=""
VIDEO_ACCEL=""

if [[ "$PROFILE" == "laptop" || "$PROFILE" == "workstation" ]]; then
	choose VIDEO_ACCEL "GPU vendor (for hardware video acceleration):" "intel" "amd" "none"
	info "Video acceleration: $VIDEO_ACCEL"

	DEFAULT_KBD="/dev/input/by-path/platform-i8042-serio-0-event-kbd"
	prompt KANATA_DEVICE "Keyboard device path for Kanata" "$DEFAULT_KBD"
	info "Kanata device: $KANATA_DEVICE"
fi

# On an already-installed system, capture the swap LUKS UUID manually for
# hibernate support. On a live ISO the UUID is read from the disk after disko.
if [[ "$PROFILE" == "laptop" && "$LIVE_ISO" == false ]]; then
	warn "Laptop profile requires the swap LUKS UUID for hibernate support."
	warn "Find it with: lsblk -o NAME,UUID | grep luks"
	prompt SWAP_LUKS_UUID "Swap LUKS UUID (leave empty to skip hibernate)"
	if [[ -n "$SWAP_LUKS_UUID" ]]; then
		SWAP_DEVICE="/dev/mapper/luks-${SWAP_LUKS_UUID}"
	fi
fi

# ---------------------------------------------------------------------------
# Live ISO: disk setup prompts
# ---------------------------------------------------------------------------
SYSTEM_DISK=""
HOME_DISK=""
SEPARATE_HOME=false
ENCRYPT=""
HOME_ENCRYPT=""
LUKS_PASSPHRASE=""
HOME_PASSPHRASE=""
ROOT_SIZE=""

if [[ "$LIVE_ISO" == true ]]; then
	# --- RAM auto-detection (for laptop swap size) --------------------------
	RAM_KB=$(grep '^MemTotal:' /proc/meminfo | awk '{print $2}')
	RAM_GB=$(((RAM_KB + 1048575) / 1048576)) # round up to nearest GiB
	SWAP_SIZE="${RAM_GB}G"
	info "Detected RAM: ${RAM_GB} GiB — swap will be set to ${SWAP_SIZE}."

	# --- Disk discovery -----------------------------------------------------
	echo ""
	info "Available block devices:"
	lsblk -dpno NAME,SIZE,MODEL | grep -v '^$' | grep -v loop || true
	echo ""

	mapfile -t ALL_DISKS < <(lsblk -dpno NAME | grep -v '^$' | grep -v loop)
	[[ ${#ALL_DISKS[@]} -eq 0 ]] && die "No block devices found."

	# --- System disk --------------------------------------------------------
	if [[ ${#ALL_DISKS[@]} -eq 1 ]]; then
		SYSTEM_DISK="${ALL_DISKS[0]}"
		info "Only one disk found — using $SYSTEM_DISK as system disk."
	else
		prompt SYSTEM_DISK "System disk (for /boot, swap, /)" ""
	fi
	[[ -b "$SYSTEM_DISK" ]] || die "Not a block device: $SYSTEM_DISK"

	# --- Separate home disk? ------------------------------------------------
	if [[ ${#ALL_DISKS[@]} -gt 1 ]]; then
		choose USE_SEPARATE_HOME "Use a separate disk for /home?" "yes" "no"
		if [[ "$USE_SEPARATE_HOME" == "yes" ]]; then
			SEPARATE_HOME=true
			prompt HOME_DISK "Home disk (for /home)" ""
			[[ "$HOME_DISK" != "$SYSTEM_DISK" ]] || die "Home disk must differ from system disk."
			[[ -b "$HOME_DISK" ]] || die "Not a block device: $HOME_DISK"
		fi
	fi

	# --- Root size (single-disk only) ---------------------------------------
	if [[ "$SEPARATE_HOME" == false ]]; then
		if [[ "$PROFILE" == "laptop" ]]; then
			info "Boot=1G, swap=${SWAP_SIZE} are reserved automatically."
		else
			info "Boot=1G is reserved automatically."
		fi
		prompt ROOT_SIZE "Root (/) partition size (e.g. 60G — /home gets the remainder)"
	fi

	# --- System disk encryption ---------------------------------------------
	choose ENCRYPT "Encrypt the system disk with LUKS?" "yes" "no"
	if [[ "$ENCRYPT" == "yes" ]]; then
		prompt_secret LUKS_PASSPHRASE "System disk LUKS passphrase"
		LUKS_CONFIRM=""
		prompt_secret LUKS_CONFIRM "Confirm passphrase"
		[[ "$LUKS_PASSPHRASE" == "$LUKS_CONFIRM" ]] || die "Passphrases do not match."
		unset LUKS_CONFIRM
	fi

	# --- Home disk encryption (separate disk only) --------------------------
	if [[ "$SEPARATE_HOME" == true ]]; then
		choose HOME_ENCRYPT "Encrypt the home disk with LUKS?" "yes" "no"
		if [[ "$HOME_ENCRYPT" == "yes" ]]; then
			choose SAME_PASS "Use the same passphrase as the system disk?" "yes" "no"
			if [[ "$SAME_PASS" == "yes" ]]; then
				HOME_PASSPHRASE="$LUKS_PASSPHRASE"
			else
				prompt_secret HOME_PASSPHRASE "Home disk LUKS passphrase"
				HOME_CONFIRM=""
				prompt_secret HOME_CONFIRM "Confirm passphrase"
				[[ "$HOME_PASSPHRASE" == "$HOME_CONFIRM" ]] || die "Passphrases do not match."
				unset HOME_CONFIRM
			fi
		fi
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
	# Resolve stable /dev/disk/by-id paths for both disks.
	resolve_disk_id() {
		local dev="$1" result=""
		while IFS= read -r link; do
			if [[ "$(readlink -f "$link")" == "$dev" ]]; then
				result="$link"
				break
			fi
		done < <(find /dev/disk/by-id -maxdepth 1 -type l 2>/dev/null | sort)
		if [[ -z "$result" ]]; then
			warn "No by-id symlink found for $dev — using raw device path."
			result="$dev"
		fi
		echo "$result"
	}

	info "Resolving disk IDs..."
	SYSTEM_DISK_ID=$(resolve_disk_id "$SYSTEM_DISK")
	info "System disk: $SYSTEM_DISK_ID"
	if [[ "$SEPARATE_HOME" == true ]]; then
		HOME_DISK_ID=$(resolve_disk_id "$HOME_DISK")
		info "Home disk:   $HOME_DISK_ID"
	fi

	info "Writing hosts/$HOSTNAME/disko.nix..."

	# Helper: wrap content in a LUKS partition if ENCRYPT=yes, else use directly.
	# $1 = LUKS name, $2 = encryption flag (yes/no), $3 = content block (indented 16 spaces)
	# We build the disko.nix as a single heredoc, branching in bash.

	if [[ "$SEPARATE_HOME" == false ]]; then
		# ── Single disk layout ───────────────────────────────────────────────
		# Partitions (in order):
		#   1. ESP   1G    vfat    /boot
		#   2. swap  RAM   [LUKS]  swap    ← laptop only
		#   3. root  SIZE  [LUKS]  ext4    /
		#   4. home  100%  [LUKS]  ext4    /home

		if [[ "$PROFILE" == "laptop" ]]; then
			if [[ "$ENCRYPT" == "yes" ]]; then
				cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Single-disk layout — ESP + encrypted swap + encrypted root + encrypted home.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk.main = {
    type = "disk";
    device = "${SYSTEM_DISK_ID}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
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
            content = {type = "swap";};
          };
        };
        root = {
          size = "${ROOT_SIZE}";
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
        home = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypthome";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
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
				cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Single-disk layout — ESP + swap + root + home (unencrypted).
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk.main = {
    type = "disk";
    device = "${SYSTEM_DISK_ID}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
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
          content = {type = "swap";};
        };
        root = {
          size = "${ROOT_SIZE}";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["noatime"];
          };
        };
        home = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/home";
            mountOptions = ["noatime"];
          };
        };
      };
    };
  };
}
NIXEOF
			fi
		else
			# workstation / server — no swap
			if [[ "$ENCRYPT" == "yes" ]]; then
				cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Single-disk layout — ESP + encrypted root + encrypted home.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk.main = {
    type = "disk";
    device = "${SYSTEM_DISK_ID}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "${ROOT_SIZE}";
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
        home = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypthome";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
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
				cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Single-disk layout — ESP + root + home (unencrypted).
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk.main = {
    type = "disk";
    device = "${SYSTEM_DISK_ID}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "${ROOT_SIZE}";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["noatime"];
          };
        };
        home = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/home";
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

	else
		# ── Two-disk layout ──────────────────────────────────────────────────
		# System disk partitions:
		#   1. ESP   1G    vfat    /boot
		#   2. swap  RAM   [LUKS]  swap    ← laptop only
		#   3. root  100%  [LUKS]  ext4    /
		# Home disk:
		#   1. home  100%  [HOME_LUKS] ext4  /home

		# Build the home disk partition block depending on HOME_ENCRYPT.
		if [[ "$HOME_ENCRYPT" == "yes" ]]; then
			HOME_PART_BLOCK='home = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypthome";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
              mountOptions = ["noatime"];
            };
          };
        };'
		else
			HOME_PART_BLOCK='home = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/home";
            mountOptions = ["noatime"];
          };
        };'
		fi

		if [[ "$PROFILE" == "laptop" ]]; then
			if [[ "$ENCRYPT" == "yes" ]]; then
				cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Two-disk layout — system: ESP + encrypted swap + encrypted root;
#                   home disk: ${HOME_ENCRYPT== "yes" && echo "encrypted" || echo "unencrypted"} /home.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk = {
    system = {
      type = "disk";
      device = "${SYSTEM_DISK_ID}";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
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
              content = {type = "swap";};
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
    home = {
      type = "disk";
      device = "${HOME_DISK_ID}";
      content = {
        type = "gpt";
        partitions = {
          ${HOME_PART_BLOCK}
        };
      };
    };
  };
}
NIXEOF
			else
				cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Two-disk layout — system: ESP + swap + root (unencrypted);
#                   home disk: ${HOME_ENCRYPT== "yes" && echo "encrypted" || echo "unencrypted"} /home.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk = {
    system = {
      type = "disk";
      device = "${SYSTEM_DISK_ID}";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
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
            content = {type = "swap";};
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
    home = {
      type = "disk";
      device = "${HOME_DISK_ID}";
      content = {
        type = "gpt";
        partitions = {
          ${HOME_PART_BLOCK}
        };
      };
    };
  };
}
NIXEOF
			fi
		else
			# workstation / server — no swap
			if [[ "$ENCRYPT" == "yes" ]]; then
				cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Two-disk layout — system: ESP + encrypted root;
#                   home disk: ${HOME_ENCRYPT== "yes" && echo "encrypted" || echo "unencrypted"} /home.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk = {
    system = {
      type = "disk";
      device = "${SYSTEM_DISK_ID}";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
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
    home = {
      type = "disk";
      device = "${HOME_DISK_ID}";
      content = {
        type = "gpt";
        partitions = {
          ${HOME_PART_BLOCK}
        };
      };
    };
  };
}
NIXEOF
			else
				cat >"$HOST_DIR/disko.nix" <<NIXEOF
# Two-disk layout — system: ESP + root (unencrypted);
#                   home disk: ${HOME_ENCRYPT== "yes" && echo "encrypted" || echo "unencrypted"} /home.
# Generated by install.sh; do not edit manually.
{...}: {
  disko.devices.disk = {
    system = {
      type = "disk";
      device = "${SYSTEM_DISK_ID}";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
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
    home = {
      type = "disk";
      device = "${HOME_DISK_ID}";
      content = {
        type = "gpt";
        partitions = {
          ${HOME_PART_BLOCK}
        };
      };
    };
  };
}
NIXEOF
			fi
		fi
	fi
	ok "hosts/$HOSTNAME/disko.nix written."
fi

# ---------------------------------------------------------------------------
# Generate hosts/<hostname>/default.nix
# ---------------------------------------------------------------------------
info "Writing hosts/$HOSTNAME/default.nix..."

# disko modules are included only for live ISO installs so that the installed
# system keeps its own filesystem/LUKS config across future rebuilds.
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
    # Swap LUKS UUID — for the initrd LUKS entry (boot.nix).
    # Empty string disables the LUKS entry (unencrypted or no swap).
    swapLuksUuid = "${SWAP_LUKS_UUID}";
    # Resume device for hibernate (power.nix).
    # Encrypted swap: "/dev/mapper/cryptswap"
    # Unencrypted swap: "/dev/disk/by-uuid/<partUuid>"
    # No hibernate: ""
    swapDevice = "${SWAP_DEVICE}";
    kanataConfig = dotfilesDir + "/kanata.kbd";
    kanataDevice = "${KANATA_DEVICE}";
    videoAcceleration = "${VIDEO_ACCEL}";
    # Primary user for greetd autologin (display.nix).
    primaryUser = "ovg";
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
    # Primary user for greetd autologin (display.nix).
    primaryUser = "ovg";
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

if grep -q "\"${HOSTNAME}\"" "$FLAKE_DIR/flake.nix"; then
	warn "$HOSTNAME already in flake.nix — skipping injection."
else
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
	info "Partitioning disk(s) with disko..."
	if [[ "$ENCRYPT" == "yes" ]]; then
		# Supply the system disk passphrase non-interactively via a key file.
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
	ok "Disk(s) partitioned and mounted at /mnt."

	# ------------------------------------------------------------------
	# Capture swap LUKS/partition UUID for laptop hibernate support.
	# ------------------------------------------------------------------
	# Partition order on the system disk:
	#   laptop: p1=ESP  p2=swap  p3=root  (single-disk also has p4=home)
	#   other:  p1=ESP  p2=root  (single-disk also has p3=home)
	if [[ "$PROFILE" == "laptop" ]]; then
		SWAP_PART=$(part "$SYSTEM_DISK" 2)
		if [[ "$ENCRYPT" == "yes" ]]; then
			SWAP_LUKS_UUID="$(blkid -s UUID -o value "$SWAP_PART")" ||
				warn "Could not read swap LUKS UUID — hibernate may not work."
			SWAP_DEVICE="/dev/mapper/cryptswap"
		else
			SWAP_PART_UUID="$(blkid -s UUID -o value "$SWAP_PART")" ||
				warn "Could not read swap partition UUID — hibernate may not work."
			SWAP_DEVICE="/dev/disk/by-uuid/${SWAP_PART_UUID}"
			SWAP_LUKS_UUID=""
		fi
		info "Swap device for hibernate: $SWAP_DEVICE"

		# Patch the placeholder values written into default.nix above.
		sed -i \
			-e "s|swapLuksUuid = \"\"|swapLuksUuid = \"${SWAP_LUKS_UUID}\"|" \
			-e "s|swapDevice = \"\"|swapDevice = \"${SWAP_DEVICE}\"|" \
			"$HOST_DIR/default.nix"
		ok "default.nix patched with swap UUIDs."
	fi

	# ------------------------------------------------------------------
	# Optional: TPM2 enrollment for password-free LUKS unlock at boot.
	# Requires: systemd-cryptenroll (part of systemd, present on NixOS ISO).
	# No PCR binding (--tpm2-pcrs="") — unlock always works, never breaks
	# on BIOS updates. Protection: disk removed to another machine = locked.
	# ------------------------------------------------------------------
	if [[ "$ENCRYPT" == "yes" ]] || [[ "${HOME_ENCRYPT:-no}" == "yes" ]]; then
		if systemd-cryptenroll --tpm2-device=list &>/dev/null 2>&1; then
			choose ENROLL_TPM "Enroll TPM2 for password-free disk unlock at boot?" "yes" "no"
			if [[ "$ENROLL_TPM" == "yes" ]]; then
				info "Enrolling LUKS partitions with TPM2..."
				TPM_KEYFILE="$(mktemp)"
				printf '%s' "$LUKS_PASSPHRASE" >"$TPM_KEYFILE"

				if [[ "$ENCRYPT" == "yes" ]]; then
					if [[ "$PROFILE" == "laptop" ]]; then
						# Partition order: ESP(1) swap(2) root(3) [home(4) single-disk]
						enroll_tpm2 "$(part "$SYSTEM_DISK" 2)" "$TPM_KEYFILE"
						enroll_tpm2 "$(part "$SYSTEM_DISK" 3)" "$TPM_KEYFILE"
						if [[ "$SEPARATE_HOME" == false ]]; then
							enroll_tpm2 "$(part "$SYSTEM_DISK" 4)" "$TPM_KEYFILE"
						fi
					else
						# workstation/server: ESP(1) root(2) [home(3) single-disk]
						enroll_tpm2 "$(part "$SYSTEM_DISK" 2)" "$TPM_KEYFILE"
						if [[ "$SEPARATE_HOME" == false ]]; then
							enroll_tpm2 "$(part "$SYSTEM_DISK" 3)" "$TPM_KEYFILE"
						fi
					fi
				fi

				rm -f "$TPM_KEYFILE"

				# Home disk (two-disk only, separately encrypted)
				if [[ "$SEPARATE_HOME" == true ]] && [[ "${HOME_ENCRYPT:-no}" == "yes" ]]; then
					HOME_TPM_KEYFILE="$(mktemp)"
					printf '%s' "$HOME_PASSPHRASE" >"$HOME_TPM_KEYFILE"
					enroll_tpm2 "$(part "$HOME_DISK" 1)" "$HOME_TPM_KEYFILE"
					rm -f "$HOME_TPM_KEYFILE"
				fi

				ok "TPM2 enrollment complete."
			fi
		else
			info "No TPM2 device found — skipping TPM2 enrollment."
			info "You can enroll manually after first boot with:"
			echo "  sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=\"\" /dev/disk/by-uuid/<luks-uuid>"
		fi
	fi

	# ------------------------------------------------------------------
	# Generate hardware configuration from the mounted /mnt.
	# ------------------------------------------------------------------
	info "Generating hardware configuration..."
	sudo nixos-generate-config --root /mnt --show-hardware-config \
		>"$HOST_DIR/hardware.nix" ||
		die "nixos-generate-config failed."
	ok "hardware.nix written."

	# Re-format after hardware.nix and any sed patches.
	alejandra "$HOST_DIR/" 2>/dev/null || true

	# ------------------------------------------------------------------
	# nixos-install
	# ------------------------------------------------------------------
	info "Running nixos-install for .#$HOSTNAME ..."
	cd "$FLAKE_DIR"
	sudo nixos-install \
		--flake ".#${HOSTNAME}" \
		--root /mnt \
		--no-root-passwd ||
		die "nixos-install failed."
	ok "NixOS installed."

	# ------------------------------------------------------------------
	# Copy dotfiles into the new system so they are available after reboot.
	# ------------------------------------------------------------------
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
